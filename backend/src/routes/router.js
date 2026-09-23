import { Router } from 'express';
import { login } from '../controllers/auth/login.js';
import { signup } from '../controllers/auth/signup.js';
import { publicUser } from '../controllers/auth/auth.helpers.js';
import { User } from '../models/users.js';
import { authenticate } from '../middleware/auth.js';
import { previewStudentId } from '../controllers/auth/auth.helpers.js';
import { Counter } from '../models/counters.js';

export const router = Router();

router.get('/health', (_request, response) => {
  response.json({ success: true, service: 'myeq-app-backend', status: 'ok' });
});

router.post('/login', login);
router.post('/signup', signup);
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
