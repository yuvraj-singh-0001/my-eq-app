import crypto from 'node:crypto';
import { GrowthConnectionInvite } from '../../models/growth-connection-invite.js';
import { User } from '../../models/users.js';
import { buildGrowthSummary, saveGrowthFeedback } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';

function requireStudent(request) {
  if (request.auth.role !== 'student') {
    throw createHttpError(403, 'This action is for student accounts.');
  }
}

export async function createParentInvite(request, response) {
  requireStudent(request);
  const student = await User.findById(request.auth.sub);
  if (!student) throw createHttpError(404, 'Student account was not found.');
  const code = crypto.randomBytes(5).toString('hex').toUpperCase();
  const codeHash = crypto.createHash('sha256').update(code).digest('hex');
  const expiresAt = new Date(Date.now() + 20 * 60 * 1000);
  await GrowthConnectionInvite.deleteMany({ student: student._id });
  await GrowthConnectionInvite.create({ student: student._id, codeHash, expiresAt });
  return response.status(201).json({
    success: true,
    data: { inviteCode: code, expiresAt },
  });
}

export async function submitOwnGrowthFeedback(request, response) {
  requireStudent(request);
  const student = await User.findById(request.auth.sub);
  if (!student) throw createHttpError(404, 'Student account was not found.');
  const feedback = await saveGrowthFeedback(request, student);
  return response.status(201).json({ success: true, data: { feedback } });
}

export async function getOwnGrowthSummary(request, response) {
  requireStudent(request);
  const student = await User.findById(request.auth.sub);
  if (!student) throw createHttpError(404, 'Student account was not found.');
  return response.json({
    success: true,
    data: await buildGrowthSummary(student),
  });
}

export async function getOwnConnections(request, response) {
  requireStudent(request);
  const student = await User.findById(request.auth.sub)
    .populate('assignedTeacher', 'fullName role teacherId')
    .populate('linkedParents', 'fullName role studentId')
    .populate('linkedPeers', 'fullName role studentId teacherId');
  if (!student) throw createHttpError(404, 'Student account was not found.');
  const people = [
    student.assignedTeacher,
    ...(student.linkedParents ?? []),
    ...(student.linkedPeers ?? []),
  ]
    .filter(Boolean)
    .map((person) => ({
      id: person._id.toString(),
      fullName: person.fullName,
      role: person.role,
      accountId: person.teacherId ?? person.studentId ?? null,
    }));
  return response.json({ success: true, data: { connections: people } });
}
