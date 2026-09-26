import { JournalNote } from '../../models/journal-notes.js';
import { User } from '../../models/users.js';
import { createHttpError } from '../auth/auth.helpers.js';
import mongoose from 'mongoose';

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
    responses: note.responses ?? [],
    customText: note.customText ?? '',
    sections: note.sections ?? [],
    createdAt: note.createdAt,
    isPrivate: note.isPrivate,
  };
}

export async function listJournalNotes(request, response) {
  ensureStudent(request);
  const requestedLimit = Number.parseInt(request.query.limit, 10);
  const limit = Number.isInteger(requestedLimit)
    ? Math.min(Math.max(requestedLimit, 1), 50)
    : 20;
  // The default journal endpoint is owner-only. A separate peer endpoint
  // checks an accepted student connection before returning shared reflections.
  const filter = { owner: request.auth.sub, isPrivate: true };
  if (request.query.cursor) {
    let cursor;
    try {
      cursor = JSON.parse(Buffer.from(request.query.cursor, 'base64url').toString());
    } catch {
      throw createHttpError(400, 'The notes page cursor is invalid.');
    }
    const createdAt = new Date(cursor.createdAt);
    if (
      Number.isNaN(createdAt.getTime()) ||
      !mongoose.isValidObjectId(cursor.id)
    ) {
      throw createHttpError(400, 'The notes page cursor is invalid.');
    }
    filter.$or = [
      { createdAt: { $lt: createdAt } },
      { createdAt, _id: { $lt: cursor.id } },
    ];
  }

  const rows = await JournalNote.find(filter)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit + 1)
    .lean();
  const hasMore = rows.length > limit;
  const notes = hasMore ? rows.slice(0, limit) : rows;
  const lastNote = notes.at(-1);
  const nextCursor = hasMore && lastNote
    ? Buffer.from(JSON.stringify({
      createdAt: lastNote.createdAt.toISOString(),
      id: lastNote._id.toString(),
    })).toString('base64url')
    : null;

  return response.json({
    success: true,
    data: { notes: notes.map(toClientNote), nextCursor, hasMore },
  });
}

export async function listConnectedStudentJournalNotes(request, response) {
  ensureStudent(request);
  if (!mongoose.isValidObjectId(request.params.studentId)) {
    throw createHttpError(400, 'That student profile is invalid.');
  }
  const [viewer, connectedStudent] = await Promise.all([
    User.findById(request.auth.sub).select('role linkedPeers').lean(),
    User.findById(request.params.studentId).select('role linkedPeers').lean(),
  ]);
  const viewerHasStudent = viewer?.linkedPeers?.some(
    (id) => String(id) === String(request.params.studentId),
  );
  const studentHasViewer = connectedStudent?.linkedPeers?.some(
    (id) => String(id) === String(request.auth.sub),
  );
  if (
    !viewer ||
    connectedStudent?.role !== 'student' ||
    !viewerHasStudent ||
    !studentHasViewer
  ) {
    throw createHttpError(403, 'Accept this student connection before viewing their reflections.');
  }

  const requestedLimit = Number.parseInt(request.query.limit, 10);
  const limit = Number.isInteger(requestedLimit)
    ? Math.min(Math.max(requestedLimit, 1), 50)
    : 20;
  const filter = { owner: connectedStudent._id, isPrivate: true };
  if (request.query.cursor) {
    let cursor;
    try {
      cursor = JSON.parse(Buffer.from(request.query.cursor, 'base64url').toString());
    } catch {
      throw createHttpError(400, 'The notes page cursor is invalid.');
    }
    const createdAt = new Date(cursor.createdAt);
    if (Number.isNaN(createdAt.getTime()) || !mongoose.isValidObjectId(cursor.id)) {
      throw createHttpError(400, 'The notes page cursor is invalid.');
    }
    filter.$or = [
      { createdAt: { $lt: createdAt } },
      { createdAt, _id: { $lt: cursor.id } },
    ];
  }
  const rows = await JournalNote.find(filter)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit + 1)
    .lean();
  const hasMore = rows.length > limit;
  const notes = hasMore ? rows.slice(0, limit) : rows;
  const lastNote = notes.at(-1);
  const nextCursor = hasMore && lastNote
    ? Buffer.from(JSON.stringify({
      createdAt: lastNote.createdAt.toISOString(),
      id: lastNote._id.toString(),
    })).toString('base64url')
    : null;
  return response.json({
    success: true,
    data: {
      notes: notes.map(toClientNote),
      nextCursor,
      hasMore,
    },
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
  const rawResponses = request.body?.responses ?? [];
  const customText = typeof request.body?.customText === 'string'
    ? request.body.customText.trim()
    : '';
  const rawSections = request.body?.sections ?? [];

  if (!category || category.length > 80) {
    throw createHttpError(400, 'Choose a valid note category.');
  }
  if (!text || text.length > 8000) {
    throw createHttpError(400, 'Write a note of up to 8000 characters.');
  }
  if (mood !== null && !allowedMoods.has(mood)) {
    throw createHttpError(400, 'Choose a valid mood.');
  }
  if (
    !Array.isArray(rawResponses) ||
    rawResponses.length > 100 ||
    rawResponses.some((value) => typeof value !== 'string' || value.trim().length > 240)
  ) {
    throw createHttpError(400, 'The selected statements are invalid.');
  }
  if (customText.length > 2000) {
    throw createHttpError(400, 'Your additional note can be up to 2000 characters.');
  }
  if (!Array.isArray(rawSections) || rawSections.length > 10) {
    throw createHttpError(400, 'The reflection sections are invalid.');
  }

  const sections = rawSections.map((section) => {
    const selectedStatements = section?.selectedStatements ?? [];
    const feelings = section?.feelings ?? [];
    const sectionText = typeof section?.customText === 'string'
      ? section.customText.trim()
      : '';
    if (
      typeof section?.subcategoryId !== 'string' ||
      section.subcategoryId.trim().length > 60 ||
      typeof section?.subcategory !== 'string' ||
      section.subcategory.trim().length > 80 ||
      !Array.isArray(selectedStatements) ||
      selectedStatements.length > 20 ||
      selectedStatements.some((value) => typeof value !== 'string' || value.trim().length > 240) ||
      !Array.isArray(feelings) ||
      feelings.length > 12 ||
      feelings.some((value) => typeof value !== 'string' || value.trim().length > 60) ||
      sectionText.length > 250
    ) {
      throw createHttpError(400, 'A reflection section is invalid.');
    }
    return {
      subcategoryId: section.subcategoryId.trim(),
      subcategory: section.subcategory.trim(),
      selectedStatements: selectedStatements.map((value) => value.trim()),
      feelings: feelings.map((value) => value.trim()),
      customText: sectionText,
    };
  });

  const note = await JournalNote.create({
    owner: request.auth.sub,
    category,
    text,
    mood,
    responses: rawResponses.map((value) => value.trim()),
    customText,
    sections,
    isPrivate: true,
  });

  return response.status(201).json({
    success: true,
    data: { note: toClientNote(note) },
  });
}
