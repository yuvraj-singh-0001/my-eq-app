import { Router } from 'express';
import { login } from '../controllers/auth/login.js';
import { signup } from '../controllers/auth/signup.js';
import { updateOwnProfile } from '../controllers/auth/profile.js';
import { publicUser } from '../controllers/auth/auth.helpers.js';
import { User } from '../models/users.js';
import { authenticate } from '../middleware/auth.js';
import { previewStudentId } from '../controllers/auth/auth.helpers.js';
import { Counter } from '../models/counters.js';
import {
  getSuggestedPeople as getStudentSuggestions,
  listConnectionRequests as listStudentConnectionRequests,
  respondToConnectionRequest as respondToStudentConnectionRequest,
  sendConnectionRequest as sendStudentConnectionRequest,
} from '../controllers/student/connections.controller.js';
import {
  createJournalNote,
  listJournalNotes,
} from '../controllers/student/journal-notes.controller.js';
import {
  getTeacherActivity,
} from '../controllers/admin/teacher-activity.controller.js';
import {
  connectToStudent as connectParentToStudent,
  getOwnConnections as getParentConnections,
  getStudentGrowthSummary as getParentStudentGrowthSummary,
  submitStudentGrowthFeedback as submitParentGrowthFeedback,
} from '../controllers/parent/growth.controller.js';
import {
  getOwnGrowthSummary,
  getOwnConnections as getStudentConnections,
  createParentInvite,
  submitOwnGrowthFeedback,
} from '../controllers/student/growth.controller.js';
import {
  getOwnActivityHistory,
  getOwnActivitySummary,
  getOwnConnections as getTeacherConnections,
  getStudentGrowthSummary as getTeacherStudentGrowthSummary,
  submitStudentGrowthFeedback as submitTeacherGrowthFeedback,
} from '../controllers/teacher/growth.controller.js';
import {
  getSuggestedPeople as getTeacherSuggestions,
  listConnectionRequests as listTeacherConnectionRequests,
  respondToConnectionRequest as respondToTeacherConnectionRequest,
  sendConnectionRequest as sendTeacherConnectionRequest,
} from '../controllers/teacher/connections.controller.js';

export const router = Router();

router.get('/health', (_request, response) => {
  response.json({ success: true, service: 'myeq-app-backend', status: 'ok' });
});

router.post('/login', login);
router.post('/signup', signup);
router.get('/student/journal/notes', authenticate, listJournalNotes);
router.post('/student/journal/notes', authenticate, createJournalNote);
router.post('/student/growth/connect/parent/invite', authenticate, createParentInvite);
router.post('/student/growth/feedback', authenticate, submitOwnGrowthFeedback);
router.get('/student/growth/summary', authenticate, getOwnGrowthSummary);
router.get('/student/growth/connections', authenticate, getStudentConnections);
router.get('/student/growth/people', authenticate, getStudentSuggestions);
router.get('/student/growth/connection-requests', authenticate, listStudentConnectionRequests);
router.post('/student/growth/connection-requests', authenticate, sendStudentConnectionRequest);
router.post('/student/growth/connection-requests/:requestId/respond', authenticate, respondToStudentConnectionRequest);
router.post('/parent/connect/student', authenticate, connectParentToStudent);
router.get('/parent/growth/connections', authenticate, getParentConnections);
router.post('/parent/students/:studentId/growth-feedback', authenticate, submitParentGrowthFeedback);
router.get('/parent/students/:studentId/growth-summary', authenticate, getParentStudentGrowthSummary);
router.post('/teacher/students/:studentId/growth-feedback', authenticate, submitTeacherGrowthFeedback);
router.get('/teacher/students/:studentId/growth-summary', authenticate, getTeacherStudentGrowthSummary);
router.get('/teacher/activity/summary', authenticate, getOwnActivitySummary);
router.get('/teacher/activity/history', authenticate, getOwnActivityHistory);
router.get('/teacher/growth/connections', authenticate, getTeacherConnections);
router.get('/teacher/growth/people', authenticate, getTeacherSuggestions);
router.get('/teacher/growth/connection-requests', authenticate, listTeacherConnectionRequests);
router.post('/teacher/growth/connection-requests', authenticate, sendTeacherConnectionRequest);
router.post('/teacher/growth/connection-requests/:requestId/respond', authenticate, respondToTeacherConnectionRequest);
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
router.patch('/me', authenticate, updateOwnProfile);
