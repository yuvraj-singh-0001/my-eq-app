import mongoose from 'mongoose';

const growthConnectionRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
      index: true,
    },
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'declined'],
      default: 'pending',
      index: true,
    },
  },
  { timestamps: true, versionKey: false },
);

growthConnectionRequestSchema.index({ requester: 1, recipient: 1, status: 1 });
growthConnectionRequestSchema.index({ recipient: 1, status: 1, createdAt: -1 });
growthConnectionRequestSchema.index(
  { requester: 1, recipient: 1 },
  { unique: true, partialFilterExpression: { status: 'pending' } },
);

export const GrowthConnectionRequest = mongoose.model(
  'GrowthConnectionRequest',
  growthConnectionRequestSchema,
);
