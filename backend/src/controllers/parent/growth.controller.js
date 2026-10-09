import crypto from 'node:crypto';
import { GrowthConnectionInvite } from '../../models/growth-connection-invite.js';
import { GrowthFeedback } from '../../models/growth-feedback.js';
import { User } from '../../models/users.js';
import { JournalNote } from '../../models/journal-notes.js';
import mongoose from 'mongoose';
import { buildGrowthSummary, findStudent, saveGrowthFeedback } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';
import { listStudentGoals } from '../../services/growth/goals.service.js';
import {
  createNotifications,
  notificationEntry,
} from '../../services/notifications/notifications.service.js';

function requireParent(request) {
  if (request.auth.role !== 'parent') {
    throw createHttpError(403, 'This action is for parent accounts.');
  }
}

async function findLinkedStudent(request, studentId) {
  const student = await findStudent(studentId);
  const isLinked = student.linkedParents?.some(
    (parentId) => parentId.toString() === request.auth.sub,
  );
  if (!isLinked) throw createHttpError(403, 'Connect with this student before sharing feedback.');
  return student;
}

export async function connectToStudent(request, response) {
  requireParent(request);
  const code = typeof request.body?.inviteCode === 'string'
    ? request.body.inviteCode.trim().toUpperCase()
    : '';
  if (!/^[A-F0-9]{10}$/.test(code)) {
    throw createHttpError(400, 'Enter a valid parent connection code.');
  }
  const codeHash = crypto.createHash('sha256').update(code).digest('hex');
  const invite = await GrowthConnectionInvite.findOneAndDelete({
    codeHash,
    expiresAt: { $gt: new Date() },
  });
  if (!invite) throw createHttpError(400, 'This parent connection code has expired or was used.');
  const parent = await User.findById(request.auth.sub);
  const student = await User.findById(invite.student);
  if (!parent || !student || parent.role !== 'parent' || student.role !== 'student') {
    throw createHttpError(400, 'This connection could not be completed.');
  }
  await Promise.all([
    User.updateOne({ _id: student._id }, { $addToSet: { linkedParents: parent._id } }),
    User.updateOne({ _id: parent._id }, { $addToSet: { linkedStudents: student._id } }),
  ]);
  return response.json({
    success: true,
    data: { student: { studentId: student.studentId, fullName: student.fullName } },
  });
}

export async function submitStudentGrowthFeedback(request, response) {
  requireParent(request);
  const student = await findLinkedStudent(request, request.params.studentId);
  const feedback = await saveGrowthFeedback(request, student);
  const parent = await User.findById(request.auth.sub).select('fullName').lean();
  const recipients = new Map([[String(student._id), 'student']]);
  if (student.assignedTeacher) {
    recipients.set(String(student.assignedTeacher), 'teacher');
  }
  await createNotifications([...recipients].map(([recipient, role]) =>
    notificationEntry({
      recipient,
      actor: request.auth.sub,
      actorName: parent?.fullName ?? 'A parent or guardian',
      actorRole: 'parent',
      type: 'growth_feedback_received',
      title: 'New family growth check-in',
      body: role === 'student'
        ? 'Your parent or guardian shared a growth check-in.'
        : `A parent or guardian shared a growth check-in for ${student.fullName}.`,
      payload: {
        studentId: String(student._id),
        feedbackId: String(feedback._id),
        destination: role === 'student' ? 'student_progress' : 'teacher_progress',
      },
    }),
  ));
  return response.status(201).json({ success: true, data: { feedback } });
}

export async function getStudentGrowthSummary(request, response) {
  requireParent(request);
  const student = await findLinkedStudent(request, request.params.studentId);
  const [summary, teacherUpdates] = await Promise.all([
    buildGrowthSummary(student),
    student.assignedTeacher
      ? GrowthFeedback.find({
          student: student._id,
          author: student.assignedTeacher,
          authorRole: 'teacher',
        })
          .sort({ createdAt: -1 })
          .limit(30)
          .populate('author', 'fullName role')
          .lean()
      : [],
  ]);
  summary.recent = summary.recent.filter((entry) => entry.authorRole !== 'teacher');
  summary.teacherUpdates = teacherUpdates.map((entry) => ({
    id: entry._id.toString(),
    teacherName: entry.author?.fullName ?? 'Connected teacher',
    focusArea: entry.focusArea,
    progress: entry.progress,
    observedBehaviors: entry.observedBehaviors ?? [],
    whatHelped: entry.whatHelped ?? '',
    whatWasHard: entry.whatWasHard ?? '',
    nextStep: entry.nextStep ?? '',
    createdAt: entry.createdAt,
  }));
  return response.json({
    success: true,
    data: summary,
  });
}

export async function getOwnConnections(request, response) {
  requireParent(request);
  const parent = await User.findById(request.auth.sub)
    .populate('linkedStudents', 'fullName role studentId className section schoolName');
  if (!parent) throw createHttpError(404, 'Parent account was not found.');
  const people = (parent.linkedStudents ?? []).map((student) => ({
    id: student._id.toString(),
    fullName: student.fullName,
    role: student.role,
    accountId: student.studentId ?? null,
    className: student.className ?? null,
    section: student.section ?? null,
    schoolName: student.schoolName ?? null,
  }));
  return response.json({ success: true, data: { connections: people } });
}

export async function getConnectedTeachers(request, response) {
  requireParent(request);
  const parent = await User.findById(request.auth.sub).select('linkedStudents').lean();
  if (!parent) throw createHttpError(404, 'Parent account was not found.');
  const students = await User.find({
    _id: { $in: parent.linkedStudents ?? [] },
    role: 'student',
    linkedParents: request.auth.sub,
  }).populate('assignedTeacher', 'fullName role teacherId username schoolName teachingSubject').lean();
  const teachers = new Map();
  for (const student of students) {
    const teacher = student.assignedTeacher;
    if (!teacher || teacher.role !== 'teacher') continue;
    teachers.set(String(teacher._id), {
      id: String(teacher._id),
      fullName: teacher.fullName,
      role: teacher.role,
      username: teacher.username,
      accountId: teacher.teacherId ?? null,
      schoolName: teacher.schoolName ?? null,
      teachingSubject: teacher.teachingSubject ?? null,
      studentName: student.fullName,
      studentId: student.studentId ?? null,
      status: 'connected',
    });
  }
  return response.json({ success: true, data: { teachers: [...teachers.values()] } });
}

export async function getStudentGoalsForParent(request, response) {
  requireParent(request);
  const student = await findLinkedStudent(request, request.params.studentId);
  if (!student.assignedTeacher) return response.json({ success: true, data: { goals: [] } });
  const goals = await listStudentGoals(student, student.assignedTeacher, request.query.status);
  return response.json({ success: true, data: { goals } });
}

export async function listSharedStudentJournalNotes(request, response) {
  requireParent(request);
  if (!mongoose.isValidObjectId(request.params.studentId)) {
    throw createHttpError(400, 'That student profile is invalid.');
  }
  const student = await User.findById(request.params.studentId)
    .select('_id role linkedParents')
    .lean();
  const linked = student?.role === 'student' && student.linkedParents?.some(
    (parentId) => parentId.toString() === request.auth.sub,
  );
  if (!linked) throw createHttpError(403, 'Connect with this student before viewing shared notes.');
  const notes = await JournalNote.find({
    owner: student._id,
    sharedWithParents: true,
  }).sort({ createdAt: -1, _id: -1 }).limit(50).lean();
  return response.json({
    success: true,
    data: {
      notes: notes.map((note) => ({
        id: note._id.toString(),
        category: note.category,
        text: note.text,
        mood: note.mood ?? null,
        responses: note.responses ?? [],
        customText: note.customText ?? '',
        sections: note.sections ?? [],
        createdAt: note.createdAt,
      })),
      hasMore: false,
      nextCursor: null,
    },
  });
}
