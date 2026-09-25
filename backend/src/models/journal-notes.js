import mongoose from 'mongoose';

const journalNoteSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
      index: true,
    },
    category: { type: String, required: true, trim: true, maxlength: 80 },
    text: { type: String, required: true, trim: true, maxlength: 5000 },
    mood: {
      type: String,
      enum: ['Great', 'Good', 'Okay', 'Low', 'Hard', null],
      default: null,
    },
    isPrivate: { type: Boolean, default: true },
  },
  { timestamps: true, versionKey: false },
);

journalNoteSchema.index({ owner: 1, createdAt: -1 });

export const JournalNote = mongoose.model('JournalNotes', journalNoteSchema);
