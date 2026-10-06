import mongoose from 'mongoose';
import { JournalNote } from '../../models/journal-notes.js';
import { JournalNoteView } from '../../models/journal-note-view.js';
import { createHttpError } from '../auth/auth.helpers.js';
import { findStudent } from '../../services/growth/growth.service.js';

function requireTeacher(request) {
  if (request.auth.role !== 'teacher') {
    throw createHttpError(403, 'This action is for teacher accounts.');
  }
}

export async function listAssignedStudentJournalNotes(request, response) {
  requireTeacher(request);
  const student = await findStudent(request.params.studentId);
  if (student.assignedTeacher?.toString() !== request.auth.sub) {
    throw createHttpError(403, 'This student has not connected with your teacher account.');
  }

  const requestedLimit = Number.parseInt(request.query.limit, 10);
  const limit = Number.isInteger(requestedLimit)
    ? Math.min(Math.max(requestedLimit, 1), 50)
    : 20;
  const filter = { owner: student._id, isPrivate: true };
  if (request.query.category) {
    if (typeof request.query.category !== 'string' || request.query.category.trim().length > 80) {
      throw createHttpError(400, 'The reflection category is invalid.');
    }
    filter.category = request.query.category.trim();
  }
  const dateFilter = {};
  for (const [key, operator] of [['from', '$gte'], ['to', '$lte']]) {
    const value = request.query[key];
    if (value !== undefined) {
      const date = new Date(value);
      if (typeof value !== 'string' || Number.isNaN(date.getTime())) {
        throw createHttpError(400, 'The reflection date filter is invalid.');
      }
      dateFilter[operator] = date;
    }
  }
  if (dateFilter.$gte && dateFilter.$lte && dateFilter.$gte > dateFilter.$lte) {
    throw createHttpError(400, 'The reflection date range is invalid.');
  }
  if (Object.keys(dateFilter).length) filter.createdAt = dateFilter;
  if (request.query.cursor) {
    let cursor;
    try {
      cursor = JSON.parse(Buffer.from(request.query.cursor, 'base64url').toString());
    } catch {
      throw createHttpError(400, 'The notes page cursor is invalid.');
    }
    if (!cursor || typeof cursor !== 'object' || Array.isArray(cursor)) {
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
  if (notes.length) {
    const viewedAt = new Date();
    try {
      await JournalNoteView.bulkWrite(notes.map((note) => ({
        updateOne: {
          filter: { note: note._id, viewer: request.auth.sub },
          update: {
            $set: { owner: student._id, lastViewedAt: viewedAt },
            $setOnInsert: { firstViewedAt: viewedAt },
          },
          upsert: true,
        },
      })), { ordered: false });
    } catch (error) {
      const duplicateOnly = error.writeErrors?.length &&
        error.writeErrors.every((writeError) => writeError.code === 11000);
      if (!duplicateOnly) throw error;
    }
  }

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
      notes: notes.map((note) => ({
        id: note._id.toString(),
        category: note.category,
        text: note.text,
        mood: note.mood ?? null,
        responses: note.responses ?? [],
        customText: note.customText ?? '',
        sections: (note.sections ?? []).map((section) => ({
          subcategory: section.subcategory ?? '',
          selectedStatements: section.selectedStatements ?? [],
          feelings: section.feelings ?? [],
          customText: section.customText ?? '',
        })),
        createdAt: note.createdAt,
      })),
      nextCursor,
      hasMore,
    },
  });
}
