import { GrowthFeedback } from '../../models/growth-feedback.js';
import { User } from '../../models/users.js';
import { createHttpError } from '../../controllers/auth/auth.helpers.js';

const focusAreas = new Set([
  'frustration',
  'calming_myself',
  'patience_waiting',
  'helpful_habits',
  'impulses',
  'changes',
  'focus',
]);
const progressValues = new Set(['improving', 'steady', 'harder', 'not_sure']);

export async function findStudent(studentId) {
  if (typeof studentId !== 'string' || !studentId.trim()) {
    throw createHttpError(400, 'Enter a valid student ID.');
  }
  const student = await User.findOne({
    studentId: studentId.trim().toUpperCase(),
    role: 'student',
  });
  if (!student) throw createHttpError(404, 'Student account was not found.');
  return student;
}

export async function saveGrowthFeedback(request, student) {
  const focusArea = request.body?.focusArea;
  const progress = request.body?.progress;
  const observedBehaviors = request.body?.observedBehaviors ?? [];
  const whatHelped = typeof request.body?.whatHelped === 'string'
    ? request.body.whatHelped.trim()
    : '';
  const whatWasHard = typeof request.body?.whatWasHard === 'string'
    ? request.body.whatWasHard.trim()
    : '';
  const nextStep = typeof request.body?.nextStep === 'string'
    ? request.body.nextStep.trim()
    : '';

  if (!focusAreas.has(focusArea) || !progressValues.has(progress)) {
    throw createHttpError(400, 'Choose a valid focus area and progress update.');
  }
  if (
    !Array.isArray(observedBehaviors) ||
    observedBehaviors.length > 12 ||
    observedBehaviors.some((item) => typeof item !== 'string' || item.trim().length > 160) ||
    whatHelped.length > 500 ||
    whatWasHard.length > 500 ||
    nextStep.length > 300
  ) {
    throw createHttpError(400, 'Keep feedback within the allowed length.');
  }

  return GrowthFeedback.create({
    student: student._id,
    author: request.auth.sub,
    authorRole: request.auth.role,
    focusArea,
    progress,
    observedBehaviors: observedBehaviors.map((item) => item.trim()),
    whatHelped,
    whatWasHard,
    nextStep,
  });
}

export async function buildGrowthSummary(student) {
  const filter = { student: student._id };
  const [groupedRows, totalCheckIns, entries] = await Promise.all([
    GrowthFeedback.aggregate([
      { $match: filter },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: { focusArea: '$focusArea', authorRole: '$authorRole' },
          checkIns: { $sum: 1 },
          improving: { $sum: { $cond: [{ $eq: ['$progress', 'improving'] }, 1, 0] } },
          steady: { $sum: { $cond: [{ $eq: ['$progress', 'steady'] }, 1, 0] } },
          harder: { $sum: { $cond: [{ $eq: ['$progress', 'harder'] }, 1, 0] } },
          notSure: { $sum: { $cond: [{ $eq: ['$progress', 'not_sure'] }, 1, 0] } },
          latestProgress: { $first: '$progress' },
          latestAt: { $first: '$createdAt' },
        },
      },
      {
        $group: {
          _id: '$_id.focusArea',
          sources: {
            $push: {
              role: '$_id.authorRole',
              checkIns: '$checkIns',
              improving: '$improving',
              steady: '$steady',
              harder: '$harder',
              notSure: '$notSure',
              latestProgress: '$latestProgress',
              latestAt: '$latestAt',
            },
          },
        },
      },
    ]),
    GrowthFeedback.countDocuments(filter),
    GrowthFeedback.find(filter)
      .sort({ createdAt: -1 })
      .limit(30)
      .populate('author', 'fullName role')
      .lean(),
  ]);

  const byFocusArea = {};
  for (const row of groupedRows) {
    byFocusArea[row._id] = Object.fromEntries(
      row.sources.map(({ role, ...stats }) => [role, stats]),
    );
  }
  return {
    student: { studentId: student.studentId, fullName: student.fullName },
    totalCheckIns,
    byFocusArea,
    recent: entries.map((entry) => ({
      id: entry._id.toString(),
      focusArea: entry.focusArea,
      progress: entry.progress,
      observedBehaviors: entry.observedBehaviors,
      whatHelped: entry.whatHelped,
      whatWasHard: entry.whatWasHard,
      nextStep: entry.nextStep,
      authorRole: entry.authorRole,
      authorName: entry.author?.fullName ?? 'Account',
      createdAt: entry.createdAt,
    })),
  };
}

export async function buildTeacherActivity(teacher) {
  const match = { author: teacher._id, authorRole: 'teacher' };
  const [totalFeedbackEntries, students, areaRows, recentRows] = await Promise.all([
    GrowthFeedback.countDocuments(match),
    GrowthFeedback.distinct('student', match),
    GrowthFeedback.aggregate([
      { $match: match },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$focusArea',
          submissions: { $sum: 1 },
          latestAt: { $first: '$createdAt' },
        },
      },
    ]),
    GrowthFeedback.find(match)
      .sort({ createdAt: -1 })
      .limit(30)
      .populate('student', 'fullName studentId')
      .lean(),
  ]);

  return {
    teacher: { teacherId: teacher.teacherId, fullName: teacher.fullName },
    totalFeedbackEntries,
    studentsSupported: students.length,
    byFocusArea: Object.fromEntries(
      areaRows.map((row) => [row._id, {
        submissions: row.submissions,
        latestAt: row.latestAt,
      }]),
    ),
    lastActivityAt: recentRows[0]?.createdAt ?? null,
    recent: recentRows.map((entry) => ({
      focusArea: entry.focusArea,
      progress: entry.progress,
      studentId: entry.student?.studentId ?? null,
      studentName: entry.student?.fullName ?? null,
      createdAt: entry.createdAt,
    })),
  };
}
