import { GrowthFeedback } from '../../models/growth-feedback.js';
import { User } from '../../models/users.js';
import { buildGrowthSummary, buildTeacherActivity, findStudent, saveGrowthFeedback } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';

function requireTeacher(request) {
  if (request.auth.role !== 'teacher') {
    throw createHttpError(403, 'This action is for teacher accounts.');
  }
}

async function findAssignedStudent(request, studentId) {
  const student = await findStudent(studentId);
  if (student.assignedTeacher?.toString() !== request.auth.sub) {
    throw createHttpError(403, 'This student has not connected with your teacher account.');
  }
  return student;
}

export async function submitStudentGrowthFeedback(request, response) {
  requireTeacher(request);
  const student = await findAssignedStudent(request, request.params.studentId);
  const feedback = await saveGrowthFeedback(request, student);
  return response.status(201).json({ success: true, data: { feedback } });
}

export async function getStudentGrowthSummary(request, response) {
  requireTeacher(request);
  const student = await findAssignedStudent(request, request.params.studentId);
  return response.json({
    success: true,
    data: await buildGrowthSummary(student),
  });
}

export async function getOwnActivitySummary(request, response) {
  requireTeacher(request);
  const teacher = await User.findById(request.auth.sub);
  if (!teacher) throw createHttpError(404, 'Teacher account was not found.');
  return response.json({
    success: true,
    data: await buildTeacherActivity(teacher),
  });
}

export async function getOwnActivityHistory(request, response) {
  requireTeacher(request);
  const entries = await GrowthFeedback.find({
    author: request.auth.sub,
    authorRole: 'teacher',
  })
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('student', 'fullName studentId')
    .lean();
  return response.json({
    success: true,
    data: {
      activities: entries.map((entry) => ({
        type: 'growth_feedback_submitted',
        studentId: entry.student?.studentId ?? null,
        studentName: entry.student?.fullName ?? null,
        focusArea: entry.focusArea,
        progress: entry.progress,
        createdAt: entry.createdAt,
      })),
    },
  });
}

export async function getOwnConnections(request, response) {
  requireTeacher(request);
  const students = await User.find({ assignedTeacher: request.auth.sub, role: 'student' })
    .select('fullName role studentId className section schoolName')
    .sort({ fullName: 1 })
    .limit(100)
    .lean();
  return response.json({
    success: true,
    data: {
      connections: students.map((student) => ({
        id: student._id.toString(),
        fullName: student.fullName,
        role: student.role,
        accountId: student.studentId ?? null,
        className: student.className ?? null,
        section: student.section ?? null,
        schoolName: student.schoolName ?? null,
      })),
    },
  });
}
