import mongoose from 'mongoose';

const growthGoalProgressSchema = new mongoose.Schema(
  {
    goal: { type: mongoose.Schema.Types.ObjectId, ref: 'GrowthGoal', required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    progress: { type: Number, required: true, min: 0, max: 100 },
    note: { type: String, trim: true, maxlength: 1000, default: '' },
  },
  { timestamps: true, versionKey: false },
);

growthGoalProgressSchema.index({ goal: 1, createdAt: 1 });
growthGoalProgressSchema.index({ student: 1, teacher: 1, createdAt: -1 });

export const GrowthGoalProgress = mongoose.model('GrowthGoalProgress', growthGoalProgressSchema);
