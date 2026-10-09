import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
    },
    actor: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', default: null },
    actorName: { type: String, trim: true, maxlength: 100, default: '' },
    actorRole: { type: String, trim: true, maxlength: 20, default: '' },
    type: {
      type: String,
      enum: [
        'student_note_saved',
        'connection_request_received',
        'connection_request_accepted',
        'connection_request_declined',
        'teacher_feedback_received',
        'growth_feedback_received',
        'daily_digest',
        'student_check_in',
      ],
      required: true,
    },
    title: { type: String, required: true, trim: true, maxlength: 100 },
    body: { type: String, required: true, trim: true, maxlength: 240 },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
    dedupeKey: { type: String, trim: true, maxlength: 220 },
    readAt: { type: Date, default: null },
  },
  { timestamps: true, versionKey: false },
);

notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, readAt: 1, createdAt: -1 });
notificationSchema.index({ type: 1, createdAt: 1, recipient: 1 });
notificationSchema.index({ dedupeKey: 1 }, { unique: true, sparse: true });

export const Notification = mongoose.model('Notification', notificationSchema);
