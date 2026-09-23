import bcrypt from 'bcryptjs';
import { User } from '../../models/users.js';
import { signupSchema } from '../../validation/auth.schemas.js';
import { config } from '../../config/config.js';
import { createHttpError, createStudentId, createToken, normalizeMobile, publicUser } from './auth.helpers.js';

export async function signup(request, response) {
  const parsed = signupSchema.safeParse(request.body);
  if (!parsed.success) {
    throw createHttpError(400, parsed.error.issues[0]?.message ?? 'Invalid signup data');
  }

  const data = parsed.data;
  const email = data.email.toLowerCase();
  const username = data.username.toLowerCase();
  const mobileNumber = normalizeMobile(data.mobileNumber);
  const fatherMobileNumber = normalizeMobile(data.father.mobileNumber);
  const motherMobileNumber = data.mother.mobileNumber
    ? normalizeMobile(data.mother.mobileNumber)
    : null;
  const existingUser = await User.findOne({
    $or: [{ email }, { mobileNumber }, { username }],
  });

  if (existingUser) {
    throw createHttpError(409, 'Email, mobile number, or username is already registered');
  }

  const passwordHash = await bcrypt.hash(data.password, config.bcryptRounds);
  const studentId = await createStudentId();
  const user = await User.create({
    ...data,
    email,
    username,
    mobileNumber,
    passwordHash,
    studentId,
    father: { ...data.father, mobileNumber: fatherMobileNumber },
    mother: { ...data.mother, mobileNumber: motherMobileNumber },
  });

  response.status(201).json({
    success: true,
    message: 'Account created successfully.',
    data: { user: publicUser(user), token: createToken(user) },
  });
}
