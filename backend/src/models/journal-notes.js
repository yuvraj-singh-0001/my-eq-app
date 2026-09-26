import mongoose from 'mongoose';

const journalNoteSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Users',
      required: true,
    },
    category: { type: String, required: true, trim: true, maxlength: 80 },
    text: { type: String, required: true, trim: true, maxlength: 8000 },
    mood: {
      type: String,
      enum: ['Great', 'Good', 'Okay', 'Low', 'Hard', null],
      default: null,
    },
    responses: {
      type: [String],
      default: [],
      validate: {
        validator: (responses) => responses.length <= 100 && responses.every((value) => value.length <= 240),
        message: 'A note can contain up to 100 short selections.',
      },
    },
    customText: { type: String, trim: true, maxlength: 2000, default: '' },
    sections: {
      type: [{
        subcategoryId: { type: String, trim: true, maxlength: 60 },
        subcategory: { type: String, trim: true, maxlength: 80 },
        selectedStatements: { type: [String], default: [] },
        feelings: { type: [String], default: [] },
        customText: { type: String, trim: true, maxlength: 250, default: '' },
      }],
      default: [],
      validate: {
        validator: (sections) => sections.length <= 10,
        message: 'A note can contain up to 10 reflection sections.',
      },
    },
    isPrivate: { type: Boolean, default: true },
  },
  { timestamps: true, versionKey: false },
);

journalNoteSchema.index({ owner: 1, createdAt: -1, _id: -1 });

export const JournalNote = mongoose.model('JournalNotes', journalNoteSchema);
