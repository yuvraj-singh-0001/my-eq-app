import mongoose from 'mongoose';

const growthFeedbackSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
    },
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
    },
    authorRole: {
      type: String,
      enum: ['student', 'teacher', 'parent'],
      required: true,
    },
    focusArea: {
      type: String,
      enum: [
        'frustration',
        'calming_myself',
        'patience_waiting',
        'helpful_habits',
        'impulses',
        'changes',
        'focus',
      ],
      required: true,
    },
    progress: {
      type: String,
      enum: ['improving', 'steady', 'harder', 'not_sure'],
      required: true,
    },
    observedBehaviors: {
      type: [String],
      default: [],
      validate: {
        validator: (items) => items.length <= 12 && items.every((item) => item.length <= 160),
        message: 'Add up to 12 short observations.',
      },
    },
    whatHelped: { type: String, trim: true, maxlength: 500, default: '' },
    whatWasHard: { type: String, trim: true, maxlength: 500, default: '' },
    nextStep: { type: String, trim: true, maxlength: 300, default: '' },
  },
  { timestamps: true, versionKey: false },
);

growthFeedbackSchema.index({ student: 1, createdAt: -1 });
growthFeedbackSchema.index({ author: 1, authorRole: 1, createdAt: -1 });

export const GrowthFeedback = mongoose.model('GrowthFeedback', growthFeedbackSchema);
