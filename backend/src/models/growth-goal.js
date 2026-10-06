import mongoose from 'mongoose';

const growthGoalSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    title: { type: String, required: true, trim: true, maxlength: 120 },
    category: {
      type: String,
      enum: ['Confidence', 'Self-Regulation', 'Communication', 'Social Skills', 'Sports', 'Study Habits', 'Public Speaking', 'Participation', 'Other'],
      required: true,
    },
    description: { type: String, trim: true, maxlength: 1000, default: '' },
    startDate: { type: Date, required: true, default: Date.now },
    reviewDate: { type: Date, default: null },
    currentProgress: { type: Number, min: 0, max: 100, default: 0 },
    currentValue: { type: Number, min: 0, default: null },
    targetValue: { type: Number, min: 0, default: null },
    teacherNote: { type: String, trim: true, maxlength: 1000, default: '' },
    status: { type: String, enum: ['active', 'completed'], default: 'active' },
    completedAt: { type: Date, default: null },
  },
  { timestamps: true, versionKey: false },
);

growthGoalSchema.index({ student: 1, teacher: 1, status: 1, updatedAt: -1 });
growthGoalSchema.index({ teacher: 1, createdAt: -1 });

export const GrowthGoal = mongoose.model('GrowthGoal', growthGoalSchema);
