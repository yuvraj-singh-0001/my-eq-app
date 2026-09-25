import mongoose from 'mongoose';

const growthConnectionInviteSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
      index: true,
    },
    codeHash: { type: String, required: true, unique: true },
    expiresAt: { type: Date, required: true, index: { expires: 0 } },
  },
  { timestamps: true, versionKey: false },
);

export const GrowthConnectionInvite = mongoose.model(
  'GrowthConnectionInvite',
  growthConnectionInviteSchema,
);
