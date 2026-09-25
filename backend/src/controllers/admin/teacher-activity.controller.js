import { User } from '../../models/users.js';
import { buildTeacherActivity } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';

export async function getTeacherActivity(request, response) {
  if (request.auth.role !== 'admin') {
    throw createHttpError(403, 'This action is for admin accounts.');
  }
  const teacherId = typeof request.params.teacherId === 'string'
    ? request.params.teacherId.trim().toUpperCase()
    : '';
  const teacher = await User.findOne({ teacherId, role: 'teacher' });
  if (!teacher) throw createHttpError(404, 'Teacher account was not found.');
  return response.json({
    success: true,
    data: await buildTeacherActivity(teacher),
  });
}
