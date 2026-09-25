import { JournalNote } from '../models/journal-notes.js';
import { createHttpError } from './auth/auth.helpers.js';

const allowedMoods = new Set(['Great', 'Good', 'Okay', 'Low', 'Hard']);

function ensureStudent(request) {
  if (request.auth.role !== 'student') {
    throw createHttpError(403, 'Only student accounts can access journal notes.');
  }
}

function toClientNote(note) {
  return {
    id: note._id.toString(),
    category: note.category,
    text: note.text,
    mood: note.mood ?? null,
    createdAt: note.createdAt,
    isPrivate: note.isPrivate,
  };
}

export async function listJournalNotes(request, response) {
  ensureStudent(request);
  const notes = await JournalNote.find({ owner: request.auth.sub })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();

  return response.json({
    success: true,
    data: { notes: notes.map(toClientNote) },
  });
}

export async function createJournalNote(request, response) {
  ensureStudent(request);
  const category = typeof request.body?.category === 'string'
    ? request.body.category.trim()
    : '';
  const text = typeof request.body?.text === 'string'
    ? request.body.text.trim()
    : '';
  const mood = request.body?.mood ?? null;

  if (!category || category.length > 80) {
    throw createHttpError(400, 'Choose a valid note category.');
  }
  if (!text || text.length > 5000) {
    throw createHttpError(400, 'Write a note of up to 5000 characters.');
  }
  if (mood !== null && !allowedMoods.has(mood)) {
    throw createHttpError(400, 'Choose a valid mood.');
  }

  const note = await JournalNote.create({
    owner: request.auth.sub,
    category,
    text,
    mood,
    isPrivate: true,
  });

  return response.status(201).json({
    success: true,
    data: { note: toClientNote(note) },
  });
}
