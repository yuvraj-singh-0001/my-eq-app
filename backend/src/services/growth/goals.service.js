import mongoose from 'mongoose';
import { GrowthGoal } from '../../models/growth-goal.js';
import { GrowthGoalProgress } from '../../models/growth-goal-progress.js';
import { createHttpError } from '../../controllers/auth/auth.helpers.js';
import { findStudent } from './growth.service.js';

const categories = new Set([
  'Confidence', 'Self-Regulation', 'Communication', 'Social Skills', 'Sports',
  'Study Habits', 'Public Speaking', 'Participation', 'Other',
]);

export async function findAssignedStudent(request) {
  if (request.auth.role !== 'teacher') {
    throw createHttpError(403, 'This action is for teacher accounts.');
  }
  const student = await findStudent(request.params.studentId);
  if (student.assignedTeacher?.toString() !== request.auth.sub) {
    throw createHttpError(403, 'This student has not connected with your teacher account.');
  }
  return student;
}

function parseDate(value, fieldName, optional = false) {
  if ((value == null || value === '') && optional) return null;
  if (typeof value !== 'string') throw createHttpError(400, `${fieldName} is invalid.`);
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw createHttpError(400, `${fieldName} is invalid.`);
  return date;
}

function boundedText(value, field, maxLength, required = false) {
  if (typeof value !== 'string') throw createHttpError(400, `${field} is invalid.`);
  const clean = value.trim();
  if ((required && !clean) || clean.length > maxLength) {
    throw createHttpError(400, `${field} must be ${required ? 'provided and ' : ''}under ${maxLength} characters.`);
  }
  return clean;
}

function progressValue(value) {
  const progress = value;
  if (typeof progress !== 'number' || !Number.isFinite(progress) || progress < 0 || progress > 100) {
    throw createHttpError(400, 'Progress must be between 0 and 100.');
  }
  return Math.round(progress);
}

export async function listStudentGoals(student, teacherId, status) {
  const filter = { student: student._id, teacher: teacherId };
  if (status !== undefined) {
    if (!['active', 'completed'].includes(status)) throw createHttpError(400, 'Choose a valid goal status.');
    filter.status = status;
  }
  const goals = await GrowthGoal.find(filter).sort({ updatedAt: -1, _id: -1 }).lean();
  return goals.map(serializeGoal);
}

export async function createStudentGoal(request, student) {
  const body = request.body ?? {};
  const title = boundedText(body.title, 'Goal title', 120, true);
  const category = body.category;
  if (typeof category !== 'string' || !categories.has(category)) throw createHttpError(400, 'Choose a valid goal category.');
  const description = body.description == null ? '' : boundedText(body.description, 'Description', 1000);
  const teacherNote = body.teacherNote == null ? '' : boundedText(body.teacherNote, 'Teacher note', 1000);
  const startDate = parseDate(body.startDate, 'Start date', true) ?? new Date();
  const reviewDate = parseDate(body.reviewDate, 'Review date', true);
  if (reviewDate && reviewDate < startDate) throw createHttpError(400, 'Review date cannot be earlier than the start date.');
  const hasCurrentValue = body.currentValue != null && body.currentValue !== '';
  const hasTargetValue = body.targetValue != null && body.targetValue !== '';
  if (hasCurrentValue !== hasTargetValue) throw createHttpError(400, 'Enter both the current value and target value, or leave both blank.');
  let currentValue = null;
  let targetValue = null;
  let currentProgress = 0;
  if (hasCurrentValue) {
    currentValue = Number(body.currentValue);
    targetValue = Number(body.targetValue);
    if (!Number.isFinite(currentValue) || !Number.isFinite(targetValue) || currentValue < 0 || targetValue <= 0 || currentValue > targetValue) {
      throw createHttpError(400, 'Current and target values must be valid, and current cannot exceed target.');
    }
    currentProgress = Math.round(currentValue * 100 / targetValue);
  }
  const goal = await GrowthGoal.create({
    student: student._id,
    teacher: request.auth.sub,
    title,
    category,
    description,
    teacherNote,
    startDate,
    reviewDate,
    currentProgress,
    currentValue,
    targetValue,
  });
  await GrowthGoalProgress.create({
    goal: goal._id,
    student: student._id,
    teacher: request.auth.sub,
    progress: currentProgress,
    note: 'Goal created',
  });
  return serializeGoal(goal.toObject());
}

async function findOwnedGoal(student, teacherId, goalId) {
  if (!mongoose.isValidObjectId(goalId)) throw createHttpError(400, 'Enter a valid goal ID.');
  const goal = await GrowthGoal.findOne({ _id: goalId, student: student._id, teacher: teacherId });
  if (!goal) throw createHttpError(404, 'Goal not found.');
  return goal;
}

export async function getStudentGoal(student, teacherId, goalId) {
  const goal = await findOwnedGoal(student, teacherId, goalId);
  const history = await GrowthGoalProgress.find({ goal: goal._id, student: student._id, teacher: teacherId })
    .sort({ createdAt: 1, _id: 1 })
    .lean();
  return { ...serializeGoal(goal.toObject()), history: history.map(serializeProgress) };
}

export async function updateStudentGoalProgress(request, student) {
  const goal = await findOwnedGoal(student, request.auth.sub, request.params.goalId);
  if (goal.status !== 'active') throw createHttpError(409, 'Completed goals cannot be updated.');
  const progress = progressValue(request.body?.progress);
  const note = request.body?.note == null ? '' : boundedText(request.body.note, 'Progress note', 1000);
  const currentValue = request.body?.currentValue;
  if (goal.targetValue != null && currentValue != null && currentValue !== '') {
    const value = Number(currentValue);
    if (!Number.isFinite(value) || value < 0 || value > goal.targetValue) throw createHttpError(400, 'Current value must be between zero and the goal target.');
    goal.currentValue = value;
    goal.currentProgress = Math.round(value * 100 / goal.targetValue);
  } else {
    goal.currentProgress = progress;
    if (goal.targetValue != null) goal.currentValue = Math.round(goal.targetValue * progress / 100);
  }
  await goal.save();
  const entry = await GrowthGoalProgress.create({ goal: goal._id, student: student._id, teacher: request.auth.sub, progress: goal.currentProgress, note });
  return { ...serializeGoal(goal.toObject()), update: serializeProgress(entry.toObject()) };
}

export async function completeStudentGoal(request, student) {
  const goal = await findOwnedGoal(student, request.auth.sub, request.params.goalId);
  if (goal.status === 'completed') return serializeGoal(goal.toObject());
  const completedAt = new Date();
  goal.status = 'completed';
  goal.currentProgress = 100;
  goal.currentValue = goal.targetValue ?? goal.currentValue;
  goal.completedAt = completedAt;
  await goal.save();
  await GrowthGoalProgress.create({
    goal: goal._id,
    student: student._id,
    teacher: request.auth.sub,
    progress: 100,
    note: 'Goal marked completed',
  });
  return serializeGoal(goal.toObject());
}

function serializeGoal(goal) {
  return {
    id: goal._id.toString(),
    studentId: goal.student.toString(),
    teacherId: goal.teacher.toString(),
    title: goal.title,
    category: goal.category,
    description: goal.description ?? '',
    startDate: goal.startDate,
    reviewDate: goal.reviewDate ?? null,
    currentProgress: goal.currentProgress,
    currentValue: goal.currentValue ?? null,
    targetValue: goal.targetValue ?? null,
    teacherNote: goal.teacherNote ?? '',
    status: goal.status,
    completedAt: goal.completedAt ?? null,
    createdAt: goal.createdAt,
    updatedAt: goal.updatedAt,
  };
}

function serializeProgress(entry) {
  return {
    id: entry._id.toString(),
    goalId: entry.goal.toString(),
    studentId: entry.student.toString(),
    teacherId: entry.teacher.toString(),
    progress: entry.progress,
    note: entry.note ?? '',
    createdAt: entry.createdAt,
  };
}
