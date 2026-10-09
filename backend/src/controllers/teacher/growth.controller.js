import { GrowthFeedback } from '../../models/growth-feedback.js';
import { User } from '../../models/users.js';
import { buildGrowthSummary, buildTeacherActivity, findStudent, saveGrowthFeedback } from '../../services/growth/growth.service.js';
import { createHttpError } from '../auth/auth.helpers.js';
import {
  createNotifications,
  notificationEntry,
} from '../../services/notifications/notifications.service.js';

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
  const teacher = await User.findById(request.auth.sub).select('fullName').lean();
  const recipients = new Map([[String(student._id), 'student']]);
  for (const parentId of student.linkedParents ?? []) {
    recipients.set(String(parentId), 'parent');
  }
  await createNotifications([...recipients].map(([recipient, role]) =>
    notificationEntry({
      recipient,
      actor: request.auth.sub,
      actorName: teacher?.fullName ?? 'Your teacher',
      actorRole: 'teacher',
      type: 'teacher_feedback_received',
      title: 'Teacher shared a progress update',
      body: role === 'student'
        ? 'Your connected teacher added a new growth update.'
        : `The connected teacher shared a progress update for ${student.fullName}.`,
      payload: {
        studentId: String(student._id),
        feedbackId: String(feedback._id),
        destination: role === 'student' ? 'student_progress' : 'parent_progress',
      },
    }),
  ));
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

export async function getAssignedStudentContact(request, response) {
  requireTeacher(request);
  const student = await findAssignedStudent(request, request.params.studentId);
  return response.json({
    success: true,
    data: { studentId: student.studentId, mobileNumber: student.mobileNumber ?? null },
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
    .populate('student', 'fullName studentId className section')
    .lean();
  return response.json({
    success: true,
    data: {
      activities: entries.map((entry) => ({
        type: 'growth_feedback_submitted',
        studentId: entry.student?.studentId ?? null,
        studentName: entry.student?.fullName ?? null,
        className: entry.student?.className ?? null,
        section: entry.student?.section ?? null,
        focusArea: entry.focusArea,
        progress: entry.progress,
        observedBehaviors: entry.observedBehaviors,
        whatHelped: entry.whatHelped,
        whatWasHard: entry.whatWasHard,
        nextStep: entry.nextStep,
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

export async function getOwnClassOverview(request, response) {
  requireTeacher(request);
  const teacherId = request.auth.sub;
  const students = await User.find({ assignedTeacher: teacherId, role: 'student' })
    .select('_id fullName studentId className section')
    .sort({ fullName: 1 })
    .limit(100)
    .lean();
  if (students.length === 0) {
    return response.json({ success: true, data: { students: [] } });
  }
  const studentIds = students.map((student) => student._id);
  const updates = await GrowthFeedback.aggregate([
    { $match: { student: { $in: studentIds } } },
    { $sort: { createdAt: -1 } },
    {
      $group: {
        _id: '$student',
        checkIns: { $sum: 1 },
        latestProgress: { $first: '$progress' },
        latestFocusArea: { $first: '$focusArea' },
        latestAt: { $first: '$createdAt' },
        improvingCount: { $sum: { $cond: [{ $eq: ['$progress', 'improving'] }, 1, 0] } },
        harderCount: { $sum: { $cond: [{ $eq: ['$progress', 'harder'] }, 1, 0] } },
      },
    },
  ]);
  const byStudent = new Map(updates.map((item) => [String(item._id), item]));
  return response.json({
    success: true,
    data: {
      students: students.map((student) => {
        const update = byStudent.get(String(student._id));
        return {
          studentId: student.studentId,
          fullName: student.fullName,
          className: student.className ?? null,
          section: student.section ?? null,
          checkIns: update?.checkIns ?? 0,
          improvingCount: update?.improvingCount ?? 0,
          harderCount: update?.harderCount ?? 0,
          latestProgress: update?.latestProgress ?? null,
          latestFocusArea: update?.latestFocusArea ?? null,
          latestAt: update?.latestAt ?? null,
        };
      }),
    },
  });
}
