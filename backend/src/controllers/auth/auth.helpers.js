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

export function compactParentId(value) {
  if (typeof value !== 'string') return value;
  const match = /^AFPD0*(\d+)$/i.exec(value.trim());
  if (!match) return value;
  const sequence = match[1].replace(/^0+(?=\d)/, '');
  return `AFPD${sequence.padStart(2, '0')}`;
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

export async function createTeacherId() {
  const counter = await Counter.findOneAndUpdate(
    { _id: 'teacherId' },
    { $inc: { sequence: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );
  return `AFD3T${String(counter.sequence).padStart(2, '0')}`;
}

export async function createParentId() {
  const counter = await Counter.findOneAndUpdate(
    { _id: 'parentId' },
    { $inc: { sequence: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );
  return `AFPD${String(counter.sequence).padStart(2, '0')}`;
}

export async function previewStudentId() {
  const counter = await Counter.findById('studentId').select('sequence');
  const nextSequence = (counter?.sequence ?? 0) + 1;
  return `AFCD2CD${String(nextSequence).padStart(6, '0')}`;
}

export async function previewParentId() {
  const counter = await Counter.findById('parentId').select('sequence');
  const nextSequence = (counter?.sequence ?? 0) + 1;
  return `AFPD${String(nextSequence).padStart(2, '0')}`;
}

export function publicUser(user) {
  return {
    id: user._id,
    studentId: user.studentId,
    teacherId: user.teacherId,
    parentId: compactParentId(user.parentId),
    fullName: user.fullName,
    email: user.email,
    mobileNumber: user.mobileNumber,
    className: user.className,
    section: user.section,
    gender: user.gender,
    username: user.username,
    role: user.role,
    schoolName: user.schoolName,
    teachingSubject: user.teachingSubject,
    father: user.father
      ? {
          name: user.father.name,
          email: user.father.email,
          mobileNumber: user.father.mobileNumber,
        }
      : null,
    mother: user.mother
      ? {
          name: user.mother.name,
          email: user.mother.email,
          mobileNumber: user.mother.mobileNumber,
        }
      : null,
    createdAt: user.createdAt,
  };
}
