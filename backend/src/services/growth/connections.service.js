import mongoose from 'mongoose';
import { GrowthConnectionRequest } from '../../models/growth-connection-request.js';
import { JournalNote } from '../../models/journal-notes.js';
import { User } from '../../models/users.js';
import { createHttpError } from '../../controllers/auth/auth.helpers.js';

const connectableRoles = new Set(['student', 'teacher']);

function requireConnectableUser(request) {
  if (!connectableRoles.has(request.auth.role)) {
    throw createHttpError(403, 'Connections are available to student and teacher accounts.');
  }
}

function toPerson(user, status = 'suggested') {
  return {
    id: user._id.toString(),
    fullName: user.fullName,
    role: user.role,
    username: user.username,
    accountId: user.studentId ?? user.teacherId ?? null,
    className: user.className ?? null,
    section: user.section ?? null,
    status,
  };
}

function escapedRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function loadStatusMap(user) {
  const [requests, peers, assignedStudents] = await Promise.all([
    GrowthConnectionRequest.find({
      status: 'pending',
      $or: [{ requester: user._id }, { recipient: user._id }],
    }).lean(),
    User.findById(user._id).select('linkedPeers assignedTeacher linkedParents').lean(),
    user.role === 'teacher'
      ? User.find({ assignedTeacher: user._id, role: 'student' }).select('_id').lean()
      : Promise.resolve([]),
  ]);
  const status = new Map();
  const connectedIds = new Set([
    ...(peers?.linkedPeers ?? []).map(String),
    ...(peers?.linkedParents ?? []).map(String),
    ...(peers?.assignedTeacher ? [String(peers.assignedTeacher)] : []),
    ...assignedStudents.map((student) => String(student._id)),
  ]);
  for (const id of connectedIds) status.set(id, 'connected');
  for (const request of requests) {
    const otherId = String(request.requester) === String(user._id)
      ? String(request.recipient)
      : String(request.requester);
    status.set(otherId, String(request.requester) === String(user._id)
      ? 'request_sent'
      : 'request_received');
  }
  return status;
}

export async function findPeople(request, response) {
  requireConnectableUser(request);
  const user = await User.findById(request.auth.sub)
    .select('role schoolName className section linkedPeers assignedTeacher linkedParents');
  if (!user) throw createHttpError(404, 'Your account was not found.');

  const search = typeof request.query.search === 'string' ? request.query.search.trim() : '';
  const status = await loadStatusMap(user);
  const baseFilter = {
    _id: { $ne: user._id },
    role: user.role === 'teacher' ? 'student' : { $in: ['student', 'teacher'] },
  };
  let filter;
  if (search) {
    const exact = search.toUpperCase();
    const searchPattern = new RegExp(escapedRegex(search), 'i');
    filter = {
      ...baseFilter,
      $or: [
        { username: searchPattern },
        { studentId: exact },
        { teacherId: exact },
      ],
    };
  } else if (user.schoolName?.trim()) {
    filter = {
      ...baseFilter,
      schoolName: new RegExp(`^${escapedRegex(user.schoolName.trim())}$`, 'i'),
    };
  } else {
    return response.json({
      success: true,
      data: { people: [], needsSchool: true },
    });
  }

  const people = await User.find(filter)
    .select('fullName role username studentId teacherId className section')
    .sort({ fullName: 1 })
    .limit(search ? 20 : 12)
    .lean();
  return response.json({
    success: true,
    data: {
      people: people
        .map((person) => toPerson(person, status.get(String(person._id)) ?? 'suggested'))
        .filter((person) => person.status !== 'connected'),
      needsSchool: !user.schoolName?.trim(),
    },
  });
}

export async function sendConnectionRequest(request, response) {
  requireConnectableUser(request);
  const identity = typeof request.body?.identity === 'string'
    ? request.body.identity.trim()
    : '';
  if (identity.length < 3 || identity.length > 80) {
    throw createHttpError(400, 'Enter a valid student or teacher ID or username.');
  }
  const requester = await User.findById(request.auth.sub)
    .select('role schoolName assignedTeacher linkedPeers');
  if (!requester) throw createHttpError(404, 'Your account was not found.');

  const normalizedIdentity = identity.toUpperCase();
  const recipient = await User.findOne({
    $or: [
      { username: identity.toLowerCase() },
      { studentId: normalizedIdentity },
      { teacherId: normalizedIdentity },
    ],
    role: requester.role === 'teacher' ? 'student' : { $in: ['student', 'teacher'] },
  }).select('_id role schoolName');
  if (!recipient) throw createHttpError(404, 'No student or teacher account matched that ID or username.');
  if (String(recipient._id) === String(requester._id)) {
    throw createHttpError(400, 'You cannot send a connection request to yourself.');
  }

  if (
    requester.schoolName?.trim() && recipient.schoolName?.trim() &&
    requester.schoolName.trim().toLowerCase() !== recipient.schoolName.trim().toLowerCase()
  ) {
    throw createHttpError(403, 'You can only connect with people from your school.');
  }
  let alreadyConnected = false;
  if (requester.role === 'teacher' && recipient.role === 'student') {
    const student = await User.findById(recipient._id).select('assignedTeacher');
    alreadyConnected = String(student?.assignedTeacher ?? '') === String(requester._id);
  } else if (recipient.role === 'teacher') {
    alreadyConnected = String(requester.assignedTeacher ?? '') === String(recipient._id);
  } else {
    alreadyConnected = requester.linkedPeers?.some((peer) => String(peer) === String(recipient._id)) ?? false;
  }
  if (alreadyConnected) throw createHttpError(409, 'You are already connected.');

  const prior = await GrowthConnectionRequest.findOne({
    status: 'pending',
    $or: [
      { requester: requester._id, recipient: recipient._id },
      { requester: recipient._id, recipient: requester._id },
    ],
  });
  if (prior) {
    const message = String(prior.requester) === String(requester._id)
      ? 'Your connection request is already waiting for a response.'
      : 'This person has already sent you a request. Check your incoming requests.';
    throw createHttpError(409, message);
  }

  const sentCount = await GrowthConnectionRequest.countDocuments({
    requester: requester._id,
    status: 'pending',
  });
  if (sentCount >= 30) {
    throw createHttpError(429, 'You have 30 pending requests. Wait for a response before sending more.');
  }

  let connectionRequest;
  try {
    connectionRequest = await GrowthConnectionRequest.create({
      requester: requester._id,
      recipient: recipient._id,
    });
  } catch (error) {
    if (error?.code === 11000) {
      throw createHttpError(409, 'A request is already waiting for this person.');
    }
    throw error;
  }
  return response.status(201).json({
    success: true,
    data: { request: { id: connectionRequest._id.toString(), status: connectionRequest.status } },
  });
}

export async function listConnectionRequests(request, response) {
  requireConnectableUser(request);
  const rows = await GrowthConnectionRequest.find({
    status: 'pending',
    $or: [{ requester: request.auth.sub }, { recipient: request.auth.sub }],
  })
    .sort({ createdAt: -1 })
    .limit(50)
    .populate('requester', 'fullName username role studentId teacherId className section schoolName')
    .populate('recipient', 'fullName username role studentId teacherId className section schoolName')
    .lean();
  const incoming = [];
  const outgoing = [];
  const previewStudentIds = request.auth.role === 'student'
    ? rows
      .filter((row) => String(row.recipient?._id) === String(request.auth.sub) && row.requester?.role === 'student')
      .map((row) => row.requester._id)
    : [];
  const previewNotes = previewStudentIds.length > 0
    ? await JournalNote.find({ owner: { $in: previewStudentIds }, isPrivate: true })
      .select('owner category sections.subcategory createdAt')
      .sort({ createdAt: -1, _id: -1 })
      .limit(500)
      .lean()
    : [];
  const headingsByStudent = new Map();
  for (const note of previewNotes) {
    const ownerId = String(note.owner);
    const headings = headingsByStudent.get(ownerId) ?? [];
    if (headings.length >= 10) continue;
    const subheadings = [...new Set((note.sections ?? [])
      .map((section) => section.subcategory?.trim())
      .filter(Boolean))];
    headings.push({ category: note.category, subheadings });
    headingsByStudent.set(ownerId, headings);
  }
  for (const row of rows) {
    const isIncoming = String(row.recipient?._id) === String(request.auth.sub);
    const person = isIncoming ? row.requester : row.recipient;
    if (!person) continue;
    const personData = toPerson(person, isIncoming ? 'request_received' : 'request_sent');
    if (isIncoming && request.auth.role === 'student' && person.role === 'student') {
      personData.schoolName = person.schoolName ?? null;
      personData.noteHeadings = headingsByStudent.get(String(person._id)) ?? [];
    }
    (isIncoming ? incoming : outgoing).push({
      id: row._id.toString(),
      createdAt: row.createdAt,
      person: personData,
    });
  }
  return response.json({ success: true, data: { incoming, outgoing } });
}

export async function respondToConnectionRequest(request, response) {
  requireConnectableUser(request);
  if (!mongoose.isValidObjectId(request.params.requestId)) {
    throw createHttpError(400, 'That connection request is invalid.');
  }
  const decision = request.body?.decision;
  if (!['accept', 'decline'].includes(decision)) {
    throw createHttpError(400, 'Choose whether to accept or decline the request.');
  }
  const connectionRequest = await GrowthConnectionRequest.findOne({
    _id: request.params.requestId,
    recipient: request.auth.sub,
    status: 'pending',
  });
  if (!connectionRequest) {
    throw createHttpError(404, 'This request is no longer waiting for a response.');
  }

  if (decision === 'accept') {
    const [sender, recipient] = await Promise.all([
      User.findById(connectionRequest.requester),
      User.findById(connectionRequest.recipient),
    ]);
    if (!sender || !recipient) throw createHttpError(404, 'An account in this request no longer exists.');
    if (sender.role === 'student' && recipient.role === 'student') {
      await Promise.all([
        User.updateOne({ _id: sender._id }, { $addToSet: { linkedPeers: recipient._id } }),
        User.updateOne({ _id: recipient._id }, { $addToSet: { linkedPeers: sender._id } }),
      ]);
    } else {
      const student = sender.role === 'student' ? sender : recipient;
      const teacher = sender.role === 'teacher' ? sender : recipient;
      if (student.role !== 'student' || teacher.role !== 'teacher') {
        throw createHttpError(400, 'Students can connect with students or teachers.');
      }
      const teacherUpdate = await User.updateOne(
        {
          _id: student._id,
          $or: [{ assignedTeacher: null }, { assignedTeacher: teacher._id }],
        },
        { $set: { assignedTeacher: teacher._id } },
      );
      if (teacherUpdate.matchedCount === 0) {
        throw createHttpError(409, 'This student already has a connected teacher.');
      }
    }
    connectionRequest.status = 'accepted';
  } else {
    connectionRequest.status = 'declined';
  }
  await connectionRequest.save();
  return response.json({ success: true, data: { status: connectionRequest.status } });
}
