import bcrypt from 'bcryptjs';
import { User } from '../../models/users.js';
import { signupSchema } from '../../validation/auth.schemas.js';
import { config } from '../../config/config.js';
import { createHttpError, createStudentId, createTeacherId, createToken, normalizeMobile, publicUser } from './auth.helpers.js';

export async function signup(request, response) {
  const parsed = signupSchema.safeParse(request.body);
  if (!parsed.success) {
    throw createHttpError(400, parsed.error.issues[0]?.message ?? 'Invalid signup data');
  }

  const data = parsed.data;
  const email = data.email.toLowerCase();
  const username = data.username.toLowerCase();
  const mobileNumber = normalizeMobile(data.mobileNumber);
  const fatherMobileNumber = data.father.mobileNumber
    ? normalizeMobile(data.father.mobileNumber)
    : null;
  const motherMobileNumber = data.mother.mobileNumber
    ? normalizeMobile(data.mother.mobileNumber)
    : null;
  const existingUser = await User.findOne({
    $or: [{ email }, { mobileNumber }, { username }],
  });

  if (existingUser) {
    if (existingUser.email === email) {
      throw createHttpError(409, 'Gmail is already registered');
    }
    if (existingUser.mobileNumber === mobileNumber) {
      throw createHttpError(409, 'Mobile number is already registered');
    }
    if (existingUser.username === username) {
      throw createHttpError(409, 'Username is already taken');
    }
    throw createHttpError(409, 'An account with these details already exists');
  }

  const passwordHash = await bcrypt.hash(data.password, config.bcryptRounds);
  const isTeacher = data.role === 'teacher';
  const accountId = isTeacher ? await createTeacherId() : await createStudentId();
  const user = await User.create({
    ...data,
    email,
    username,
    mobileNumber,
    passwordHash,
    ...(isTeacher ? { teacherId: accountId } : { studentId: accountId }),
    father: isTeacher ? undefined : { ...data.father, mobileNumber: fatherMobileNumber },
    mother: { ...data.mother, mobileNumber: motherMobileNumber },
  });

  response.status(201).json({
    success: true,
    message: 'Account created successfully.',
    data: { user: publicUser(user), token: createToken(user) },
  });
}
