import jwt from 'jsonwebtoken';
import { config } from '../../config/config.js';
import { Counter } from '../../models/counters.js';

export function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

export function normalizeMobile(value) {
  return value.replace(/\D/g, '');
}

export function createToken(user) {
  return jwt.sign(
    { sub: user._id.toString(), role: user.role, username: user.username },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn },
  );
}

export async function createStudentId() {
  const counter = await Counter.findOneAndUpdate(
    { _id: 'studentId' },
    { $inc: { sequence: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );
  return `AFCD2CD${String(counter.sequence).padStart(6, '0')}`;
}

export function publicUser(user) {
  return {
    id: user._id,
    studentId: user.studentId,
    fullName: user.fullName,
    email: user.email,
    mobileNumber: user.mobileNumber,
    className: user.className,
    section: user.section,
    gender: user.gender,
    username: user.username,
    role: user.role,
  };
}
