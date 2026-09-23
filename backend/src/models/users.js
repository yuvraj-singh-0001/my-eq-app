import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true, trim: true, maxlength: 100 },
    email: { type: String, required: true, lowercase: true, trim: true, unique: true, index: true },
    mobileNumber: { type: String, required: true, unique: true, index: true },
    className: { type: String, enum: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5'] },
    section: { type: String, enum: ['A', 'B', 'C', 'D'], default: null },
    gender: { type: String, enum: ['Male', 'Female', 'Other'], default: null },
    studentId: { type: String, unique: true, sparse: true, index: true },
    teacherId: { type: String, unique: true, sparse: true, index: true },
    schoolName: { type: String, trim: true, maxlength: 150 },
    teachingSubject: { type: String, trim: true, maxlength: 80 },
    father: {
      name: { type: String, trim: true, maxlength: 100 },
      mobileNumber: { type: String },
      email: { type: String, default: null, lowercase: true, trim: true },
    },
    mother: {
      name: { type: String, default: null, trim: true },
      mobileNumber: { type: String, default: null },
      email: { type: String, default: null, lowercase: true, trim: true },
    },
    assignedTeacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', default: null },
    username: { type: String, required: true, lowercase: true, trim: true, unique: true, index: true },
    passwordHash: { type: String, required: true, select: false },
    role: { type: String, enum: ['student', 'teacher', 'parent', 'admin'], default: 'student' },
  },
  { timestamps: true, versionKey: false },
);

export const User = mongoose.model('Users', userSchema, 'Users');
