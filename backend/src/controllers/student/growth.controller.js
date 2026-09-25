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

export async function connectTeacher(request, response) {
  requireStudent(request);
  const teacherId = typeof request.body?.teacherId === 'string'
    ? request.body.teacherId.trim().toUpperCase()
    : '';
  const teacher = await User.findOne({ teacherId, role: 'teacher' });
  if (!teacher) throw createHttpError(404, 'Teacher ID was not found.');

  const student = await User.findById(request.auth.sub);
  if (!student) throw createHttpError(404, 'Student account was not found.');
  if (student.assignedTeacher && student.assignedTeacher.toString() !== teacher.id) {
    throw createHttpError(409, 'A teacher is already connected to this student.');
  }
  student.assignedTeacher = teacher._id;
  await student.save();
  return response.json({
    success: true,
    data: { teacher: { teacherId: teacher.teacherId, fullName: teacher.fullName } },
  });
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
