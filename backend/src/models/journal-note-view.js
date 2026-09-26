import mongoose from 'mongoose';

const journalNoteViewSchema = new mongoose.Schema(
  {
    note: { type: mongoose.Schema.Types.ObjectId, ref: 'JournalNotes', required: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    viewer: { type: mongoose.Schema.Types.ObjectId, ref: 'Users', required: true },
    firstViewedAt: { type: Date, required: true, default: Date.now },
    lastViewedAt: { type: Date, required: true, default: Date.now },
  },
  { timestamps: true, versionKey: false },
);

journalNoteViewSchema.index({ note: 1, viewer: 1 }, { unique: true });
journalNoteViewSchema.index({ owner: 1, note: 1, lastViewedAt: -1 });

export const JournalNoteView = mongoose.model('JournalNoteViews', journalNoteViewSchema);
