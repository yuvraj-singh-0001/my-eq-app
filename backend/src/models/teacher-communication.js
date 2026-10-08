import mongoose from 'mongoose';

const teacherCommunicationSchema = new mongoose.Schema(
  {
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    channel: { type: String, enum: ['whatsapp', 'call'], required: true },
    completed: { type: Boolean, required: true },
  },
  { timestamps: true, versionKey: false },
);

teacherCommunicationSchema.index({ teacher: 1, createdAt: -1 });
teacherCommunicationSchema.index({ student: 1, createdAt: -1 });

export const TeacherCommunication = mongoose.model(
  'TeacherCommunication',
  teacherCommunicationSchema,
);
