import { User } from '../../models/users.js';
import { profileUpdateSchema } from '../../validation/auth.schemas.js';
import { createHttpError, publicUser } from './auth.helpers.js';

export async function updateOwnProfile(request, response) {
  const user = await User.findById(request.auth.sub);
  if (!user) throw createHttpError(404, 'User account was not found.');

  const parsed = profileUpdateSchema.safeParse({
    ...request.body,
    role: user.role,
  });
  if (!parsed.success) {
    throw createHttpError(
      400,
      parsed.error.issues[0]?.message ?? 'Check your profile details.',
    );
  }

  const data = parsed.data;
  user.fullName = data.fullName.trim();
  user.email = data.email.trim().toLowerCase();
  user.mobileNumber = data.mobileNumber;
  user.username = data.username.trim().toLowerCase();
  user.gender = data.gender ?? null;
  if (user.role === 'student' || user.role === 'teacher') {
    user.schoolName = data.schoolName?.trim() || null;
  }

  if (user.role === 'student') {
    user.className = data.className;
    user.section = data.section ?? null;
    user.father = {
      name: data.father.name?.trim() ?? '',
      email: data.father.email?.trim().toLowerCase() || null,
      mobileNumber: data.father.mobileNumber || null,
    };
    user.mother = {
      name: data.mother.name?.trim() ?? '',
      email: data.mother.email?.trim().toLowerCase() || null,
      mobileNumber: data.mother.mobileNumber || null,
    };
  }

  if (user.role === 'teacher') {
    user.teachingSubject = data.teachingSubject?.trim() || null;
  }

  await user.save();
  return response.json({ success: true, data: { user: publicUser(user) } });
}
