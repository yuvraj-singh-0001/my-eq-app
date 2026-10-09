import bcrypt from 'bcryptjs';
import { User } from '../../models/users.js';
import { loginSchema } from '../../validation/auth.schemas.js';
import { compactParentId, createHttpError, createToken, normalizeMobile, publicUser } from './auth.helpers.js';

export async function login(request, response) {
  const parsed = loginSchema.safeParse(request.body);
  if (!parsed.success) {
    throw createHttpError(400, parsed.error.issues[0]?.message ?? 'Invalid login data');
  }

  const { identifier, password, role } = parsed.data;
  const trimmed = identifier.trim();
  const accountId = trimmed.toUpperCase();
  const normalizedIdentifier = trimmed.toLowerCase();
  const mobileNumber = normalizeMobile(identifier);
  const compactId = compactParentId(accountId);
  const parentIdMatch = /^AFPD0*(\d+)$/i.exec(accountId);
  const parentIdCandidates = parentIdMatch
    ? [...new Set([
      accountId,
      compactId,
      `AFPD${parentIdMatch[1].replace(/^0+(?=\d)/, '').padStart(6, '0')}`,
    ])]
    : [accountId];
  const user = await User.findOne({
    $or: [
      { email: normalizedIdentifier },
      { username: normalizedIdentifier },
      { teacherId: accountId },
      { studentId: accountId },
      { parentId: { $in: parentIdCandidates } },
      { mobileNumber },
    ],
  }).select('+passwordHash');

  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw createHttpError(401, 'Invalid role, username or password.');
  }

  if (role && user.role !== role) {
    throw createHttpError(
      403,
      'Invalid role, username or password.',
    );
  }

  response.json({
    success: true,
    data: { user: publicUser(user), token: createToken(user) },
  });
}
