import crypto from 'node:crypto';
import { GrowthConnectionInvite } from '../../models/growth-connection-invite.js';
import { User } from '../../models/users.js';
import { buildGrowthSummary, findStudent, saveGrowthFeedback } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';

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
  return response.status(201).json({ success: true, data: { feedback } });
}

export async function getStudentGrowthSummary(request, response) {
  requireParent(request);
  const student = await findLinkedStudent(request, request.params.studentId);
  return response.json({
    success: true,
    data: await buildGrowthSummary(student),
  });
}

export async function getOwnConnections(request, response) {
  requireParent(request);
  const parent = await User.findById(request.auth.sub)
    .populate('linkedStudents', 'fullName role studentId');
  if (!parent) throw createHttpError(404, 'Parent account was not found.');
  const people = (parent.linkedStudents ?? []).map((student) => ({
    id: student._id.toString(),
    fullName: student.fullName,
    role: student.role,
    accountId: student.studentId ?? null,
  }));
  return response.json({ success: true, data: { connections: people } });
}
