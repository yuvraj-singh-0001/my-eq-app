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

export async function getAssignedStudentReflectionOverview(request, response) {
  requireTeacher(request);
  const student = await findStudent(request.params.studentId);
  if (student.assignedTeacher?.toString() !== request.auth.sub) {
    throw createHttpError(403, 'This student has not connected with your teacher account.');
  }

  const daysValue = request.query.days ?? '3';
  if (daysValue !== 'all' && !['3', '5'].includes(daysValue)) {
    throw createHttpError(400, 'Choose a valid reflection date range.');
  }
  const filter = { owner: student._id, isPrivate: true };
  if (daysValue !== 'all') {
    filter.createdAt = {
      $gte: new Date(Date.now() - Number(daysValue) * 24 * 60 * 60 * 1000),
    };
  }

  const moodScore = {
    $switch: {
      branches: [
        { case: { $eq: ['$mood', 'Great'] }, then: 5 },
        { case: { $eq: ['$mood', 'Good'] }, then: 4 },
        { case: { $eq: ['$mood', 'Okay'] }, then: 3 },
        { case: { $eq: ['$mood', 'Low'] }, then: 2 },
        { case: { $eq: ['$mood', 'Hard'] }, then: 1 },
      ],
      default: null,
    },
  };
  const [totalReflections, moods, trend, categories, feelings] = await Promise.all([
    JournalNote.countDocuments(filter),
    JournalNote.aggregate([
      { $match: { ...filter, mood: { $in: ['Great', 'Good', 'Okay', 'Low', 'Hard'] } } },
      { $group: { _id: '$mood', count: { $sum: 1 } } },
    ]),
    JournalNote.aggregate([
      { $match: { ...filter, mood: { $in: ['Great', 'Good', 'Okay', 'Low', 'Hard'] } } },
      { $addFields: { moodScore: moodScore } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt', timezone: 'Asia/Kolkata' } },
          average: { $avg: '$moodScore' },
          entries: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]),
    JournalNote.aggregate([
      { $match: filter },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1, _id: 1 } },
      { $limit: 8 },
    ]),
    JournalNote.aggregate([
      { $match: filter },
      { $unwind: '$sections' },
      { $unwind: '$sections.feelings' },
      { $group: { _id: '$sections.feelings', count: { $sum: 1 } } },
      { $sort: { count: -1, _id: 1 } },
      { $limit: 8 },
    ]),
  ]);

  const moodCounts = Object.fromEntries(moods.map(({ _id, count }) => [_id, count]));
  const lowOrHard = (moodCounts.Low ?? 0) + (moodCounts.Hard ?? 0);
  const positive = (moodCounts.Great ?? 0) + (moodCounts.Good ?? 0);
  const topMood = [...moods].sort((a, b) => b.count - a.count)[0];
  const topTopics = categories.slice(0, 2).map(({ _id }) => _id).filter(Boolean);
  const topFeelings = feelings.slice(0, 2).map(({ _id }) => _id).filter(Boolean);
  let autoOverview;
  if (!totalReflections) {
    autoOverview = 'There are no saved reflections in this date range, so there is not enough information for an overview.';
  } else if (totalReflections === 1) {
    const moodText = topMood ? ` The selected mood was ${topMood._id}.` : ' No mood was selected.';
    const topicText = topTopics.length ? ` The reflection topic was ${topTopics.join(' and ')}.` : '';
    const feelingText = topFeelings.length ? ` The student selected ${topFeelings.join(' and ')} as feelings.` : '';
    autoOverview = `One reflection was saved in this date range.${moodText}${topicText}${feelingText} This is one check-in, not a trend; invite the student to share more if they wish.`;
  } else {
    const moodText = topMood
      ? ` ${topMood._id} was the most frequently selected mood (${topMood.count} of ${totalReflections} entries).`
      : ' No mood labels were recorded.';
    const topicText = topTopics.length ? ` Common topics included ${topTopics.join(' and ')}.` : '';
    const feelingText = topFeelings.length ? ` Commonly selected feelings included ${topFeelings.join(' and ')}.` : '';
    const supportText = lowOrHard > 0
      ? ` Low or Hard was selected in ${lowOrHard} ${lowOrHard === 1 ? 'entry' : 'entries'}; consider a supportive check-in to understand what would help.`
      : positive > 0
        ? ` Great or Good was selected in ${positive} ${positive === 1 ? 'entry' : 'entries'}.`
        : '';
    autoOverview = `This overview uses ${totalReflections} saved reflections in the selected date range.${moodText}${topicText}${feelingText}${supportText} These are student-selected check-ins, not a diagnosis.`;
  }

  return response.json({
    success: true,
    data: {
      days: daysValue,
      totalReflections,
      moodCounts,
      trend: trend.map((point) => ({ date: point._id, average: point.average, entries: point.entries })),
      categoryCounts: categories.map(({ _id, count }) => ({ category: _id, count })),
      feelings: feelings.map(({ _id, count }) => ({ feeling: _id, count })),
      autoOverview,
    },
  });
}
