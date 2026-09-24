import { z } from 'zod';

const emailSchema = z.string().trim().email('Enter a valid Gmail address');
const mobileSchema = z.string().regex(/^\d{10}$/, 'Mobile number must be exactly 10 digits');
const optionalEmailSchema = emailSchema.optional().or(z.literal(''));
const optionalMobileSchema = mobileSchema.optional().or(z.literal(''));
const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must include an uppercase letter')
  .regex(/[a-z]/, 'Password must include a lowercase letter')
  .regex(/[0-9]/, 'Password must include a number')
  .regex(/[^A-Za-z0-9]/, 'Password must include a special character');

export const signupSchema = z.object({
  role: z.enum(['student', 'teacher']).default('student'),
  fullName: z.string().trim().min(1, 'Full name is required').max(100),
  email: emailSchema,
  mobileNumber: mobileSchema,
  className: z.enum(['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5']).optional().nullable(),
  section: z.enum(['A', 'B', 'C', 'D']).optional().nullable(),
  gender: z.enum(['Male', 'Female', 'Other']).optional().nullable(),
  father: z.object({
    name: z.string().trim().max(100).optional().or(z.literal('')),
    mobileNumber: optionalMobileSchema,
    email: optionalEmailSchema,
  }),
  mother: z.object({
    name: z.string().trim().max(100).optional().or(z.literal('')),
    mobileNumber: optionalMobileSchema,
    email: optionalEmailSchema,
  }).default({}),
  schoolName: z.string().trim().max(150).optional().or(z.literal('')),
  teachingSubject: z.string().trim().max(80).optional().or(z.literal('')),
  username: z.string().trim().min(3).max(40).regex(/^[a-zA-Z0-9._-]+$/, 'Username contains invalid characters'),
  password: passwordSchema,
}).superRefine((data, context) => {
  if (data.role === 'student') {
    if (!data.className) context.addIssue({ code: 'custom', path: ['className'], message: 'Class is required' });
    if (!data.father.name) context.addIssue({ code: 'custom', path: ['father', 'name'], message: 'Father name is required' });
    if (!data.father.mobileNumber) context.addIssue({ code: 'custom', path: ['father', 'mobileNumber'], message: 'Father mobile number is required' });
  }
  if (data.role === 'teacher') {
    if (!data.schoolName) context.addIssue({ code: 'custom', path: ['schoolName'], message: 'School name is required' });
    if (!data.teachingSubject) context.addIssue({ code: 'custom', path: ['teachingSubject'], message: 'Teaching subject is required' });
  }
});

export const loginSchema = z.object({
  identifier: z.string().trim().min(1, 'Email, mobile number, or username is required'),
  password: z.string().min(1, 'Password is required'),
  role: z.enum(['student', 'teacher', 'parent', 'admin']).optional(),
});
