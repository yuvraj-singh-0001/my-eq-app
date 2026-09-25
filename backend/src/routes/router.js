import { Router } from 'express';
import { login } from '../controllers/auth/login.js';
import { signup } from '../controllers/auth/signup.js';
import { publicUser } from '../controllers/auth/auth.helpers.js';
import { User } from '../models/users.js';
import { authenticate } from '../middleware/auth.js';
import { previewStudentId } from '../controllers/auth/auth.helpers.js';
import { Counter } from '../models/counters.js';
import {
  createJournalNote,
  listJournalNotes,
} from '../controllers/student/journal-notes.controller.js';
import {
  getTeacherActivity,
} from '../controllers/admin/teacher-activity.controller.js';
import {
  connectToStudent as connectParentToStudent,
  getStudentGrowthSummary as getParentStudentGrowthSummary,
  submitStudentGrowthFeedback as submitParentGrowthFeedback,
} from '../controllers/parent/growth.controller.js';
import {
  getOwnGrowthSummary,
  connectTeacher,
  createParentInvite,
  submitOwnGrowthFeedback,
} from '../controllers/student/growth.controller.js';
import {
  getOwnActivityHistory,
  getOwnActivitySummary,
  getStudentGrowthSummary as getTeacherStudentGrowthSummary,
  submitStudentGrowthFeedback as submitTeacherGrowthFeedback,
} from '../controllers/teacher/growth.controller.js';

export const router = Router();

router.get('/health', (_request, response) => {
  response.json({ success: true, service: 'myeq-app-backend', status: 'ok' });
});

router.post('/login', login);
router.post('/signup', signup);
router.get('/student/journal/notes', authenticate, listJournalNotes);
router.post('/student/journal/notes', authenticate, createJournalNote);
router.post('/student/growth/connect/teacher', authenticate, connectTeacher);
router.post('/student/growth/connect/parent/invite', authenticate, createParentInvite);
router.post('/student/growth/feedback', authenticate, submitOwnGrowthFeedback);
router.get('/student/growth/summary', authenticate, getOwnGrowthSummary);
router.post('/parent/connect/student', authenticate, connectParentToStudent);
router.post('/parent/students/:studentId/growth-feedback', authenticate, submitParentGrowthFeedback);
router.get('/parent/students/:studentId/growth-summary', authenticate, getParentStudentGrowthSummary);
router.post('/teacher/students/:studentId/growth-feedback', authenticate, submitTeacherGrowthFeedback);
router.get('/teacher/students/:studentId/growth-summary', authenticate, getTeacherStudentGrowthSummary);
router.get('/teacher/activity/summary', authenticate, getOwnActivitySummary);
router.get('/teacher/activity/history', authenticate, getOwnActivityHistory);
router.get('/admin/teachers/:teacherId/activity', authenticate, getTeacherActivity);

router.get('/check-availability', async (request, response) => {
  const { email, mobileNumber, username } = request.query;
  const filter = [];
  if (email) filter.push({ email: email.toLowerCase().trim() });
  if (mobileNumber) filter.push({ mobileNumber: mobileNumber.replace(/\D/g, '') });
  if (username) filter.push({ username: username.toLowerCase().trim() });

  if (filter.length === 0) {
    return response.json({ success: true, available: true });
  }

  const existing = await User.findOne({ $or: filter });
  if (!existing) {
    return response.json({ success: true, available: true });
  }

  let field = 'Field';
  if (email && existing.email === email.toLowerCase().trim()) field = 'Gmail';
  else if (mobileNumber && existing.mobileNumber === mobileNumber.replace(/\D/g, '')) field = 'Mobile number';
  else if (username && existing.username === username.toLowerCase().trim()) field = 'Username';

  return response.json({
    success: true,
    available: false,
    message: `${field} is already registered`,
  });
});

router.get('/account-id', async (request, response) => {
  const role = request.query.role === 'teacher' ? 'teacher' : 'student';
  if (role === 'teacher') {
    const counter = await Counter.findById('teacherId').select('sequence');
    const nextSequence = (counter?.sequence ?? 0) + 1;
    return response.json({
      success: true,
      data: { accountId: `AFD3T${String(nextSequence).padStart(2, '0')}` },
    });
  }
  return response.json({ success: true, data: { accountId: await previewStudentId() } });
});

router.get('/me', authenticate, async (request, response) => {
  const user = await User.findById(request.auth.sub);
  if (!user) {
    return response.status(404).json({ success: false, message: 'User not found' });
  }

  return response.json({ success: true, data: { user: publicUser(user) } });
});
