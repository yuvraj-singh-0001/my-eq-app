import bcrypt from 'bcryptjs';
import { User } from '../../models/users.js';
import { loginSchema } from '../../validation/auth.schemas.js';
import { createHttpError, createToken, normalizeMobile, publicUser } from './auth.helpers.js';

export async function login(request, response) {
  const parsed = loginSchema.safeParse(request.body);
  if (!parsed.success) {
    throw createHttpError(400, parsed.error.issues[0]?.message ?? 'Invalid login data');
  }

  const { identifier, password } = parsed.data;
  const normalizedIdentifier = identifier.toLowerCase();
  const mobileNumber = normalizeMobile(identifier);
  const user = await User.findOne({
    $or: [
      { email: normalizedIdentifier },
      { username: normalizedIdentifier },
      { mobileNumber },
    ],
  }).select('+passwordHash');

  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw createHttpError(401, 'Invalid login details');
  }

  response.json({
    success: true,
    data: { user: publicUser(user), token: createToken(user) },
  });
}
