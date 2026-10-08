import mongoose from 'mongoose';
import { TeacherCommunication } from '../../models/teacher-communication.js';
import { findStudent } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';

function requireTeacher(request) {
  if (request.auth.role !== 'teacher') {
    throw createHttpError(403, 'This action is for teacher accounts.');
  }
}

export async function createTeacherCommunication(request, response) {
  requireTeacher(request);
  const student = await findStudent(request.params.studentId);
  if (student.assignedTeacher?.toString() !== request.auth.sub) {
    throw createHttpError(403, 'This student has not connected with your teacher account.');
  }
  const { channel, completed } = request.body ?? {};
  if (!['whatsapp', 'call'].includes(channel) || typeof completed !== 'boolean') {
    throw createHttpError(400, 'Choose a valid communication method and outcome.');
  }
  const entry = await TeacherCommunication.create({
    teacher: request.auth.sub,
    student: student._id,
    channel,
    completed,
  });
  return response.status(201).json({
    success: true,
    data: { communication: { id: entry._id.toString(), channel, completed, createdAt: entry.createdAt } },
  });
}

export async function listTeacherCommunications(request, response) {
  requireTeacher(request);
  if (!mongoose.isValidObjectId(request.auth.sub)) {
    throw createHttpError(401, 'Sign in again to view communication history.');
  }
  const entries = await TeacherCommunication.find({ teacher: request.auth.sub })
    .sort({ createdAt: -1, _id: -1 })
    .limit(100)
    .populate('student', 'fullName studentId className section')
    .lean();
  return response.json({
    success: true,
    data: {
      communications: entries.map((entry) => ({
        id: entry._id.toString(),
        studentId: entry.student?.studentId ?? null,
        studentName: entry.student?.fullName ?? 'Student',
        className: entry.student?.className ?? null,
        section: entry.student?.section ?? null,
        channel: entry.channel,
        completed: entry.completed,
        createdAt: entry.createdAt,
      })),
    },
  });
}
