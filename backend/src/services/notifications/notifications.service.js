import { Notification } from '../../models/notification.js';
import { JournalNote } from '../../models/journal-notes.js';
import { User } from '../../models/users.js';

const sixHoursMs = 6 * 60 * 60 * 1000;
const kolkataOffsetMs = 330 * 60 * 1000;
let lastDigestCycleKey = '';
let digestCycleRunning = false;

export async function createNotifications(entries) {
  const validEntries = entries.filter((entry) => entry?.recipient && entry?.type);
  if (validEntries.length === 0) return;

  try {
    await Notification.insertMany(validEntries, { ordered: false });
  } catch (error) {
    // Do not turn a successfully saved reflection or request into a failed action
    // only because its in-app notification could not be recorded.
    console.error('Could not save in-app notification:', error.message);
  }
}

export function notificationEntry({
  recipient,
  actor,
  actorName,
  actorRole,
  type,
  title,
  body,
  payload = {},
  dedupeKey,
}) {
  return {
    recipient,
    actor: actor ?? null,
    actorName: actorName ?? '',
    actorRole: actorRole ?? '',
    type,
    title,
    body,
    payload,
    dedupeKey,
  };
}

function recentCompletedWindows(now) {
  const localNow = new Date(now.getTime() + kolkataOffsetMs);
  const endHour = Math.floor(localNow.getUTCHours() / 6) * 6;
  const currentEndLocal = Date.UTC(
    localNow.getUTCFullYear(),
    localNow.getUTCMonth(),
    localNow.getUTCDate(),
    endHour,
  );
  const endLocal = new Date(currentEndLocal);
  const startLocal = new Date(endLocal.getTime() - sixHoursMs);
  const windowKey = `${endLocal.getUTCFullYear()}-${String(endLocal.getUTCMonth() + 1).padStart(2, '0')}-${String(endLocal.getUTCDate()).padStart(2, '0')}-${String(endLocal.getUTCHours()).padStart(2, '0')}`;
  return [{
    key: windowKey,
    start: new Date(startLocal.getTime() - kolkataOffsetMs),
    end: new Date(endLocal.getTime() - kolkataOffsetMs),
  }];
}

export async function createDueNotificationDigests(now = new Date()) {
  const windows = recentCompletedWindows(now);
  const cycleKey = windows.map((window) => window.key).join('|');
  if (cycleKey === lastDigestCycleKey || digestCycleRunning) return;
  digestCycleRunning = true;

  try {
    await createDueStudentCheckIns(now);
    for (const window of windows) {
      const grouped = await Notification.aggregate([
      {
        $match: {
          createdAt: { $gte: window.start, $lt: window.end },
          type: {
            $in: [
              'student_note_saved',
              'teacher_feedback_received',
              'growth_feedback_received',
            ],
          },
        },
      },
      {
        $group: {
          _id: '$recipient',
          reflections: {
            $sum: { $cond: [{ $eq: ['$type', 'student_note_saved'] }, 1, 0] },
          },
          progressUpdates: {
            $sum: {
              $cond: [
                { $in: ['$type', ['teacher_feedback_received', 'growth_feedback_received']] },
                1,
                0,
              ],
            },
          },
        },
      },
      ]);

      for (const row of grouped) {
        const recipient = String(row._id);
        const details = [];
        if (row.reflections) details.push(`${row.reflections} reflection${row.reflections === 1 ? '' : 's'}`);
        if (row.progressUpdates) details.push(`${row.progressUpdates} progress update${row.progressUpdates === 1 ? '' : 's'}`);
        await createNotifications([
          notificationEntry({
            recipient,
            actorName: 'MindGrow',
            actorRole: 'system',
            type: 'daily_digest',
            title: 'Your MindGrow growth summary',
            body: `${details.join(' and ')} arrived in the last six hours. Open Notifications to review them.`,
            payload: { destination: 'notifications', windowKey: window.key },
            dedupeKey: `daily-digest:${recipient}:${window.key}`,
          }),
        ]);
      }
    }
    lastDigestCycleKey = cycleKey;
  } finally {
    digestCycleRunning = false;
  }
}

function kolkataDateParts(date) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  return Object.fromEntries(parts.map(({ type, value }) => [type, value]));
}

async function createDueStudentCheckIns(now) {
  const local = kolkataDateParts(now);
  if (Number(local.hour) < 18) return;

  const dayKey = `${local.year}-${local.month}-${local.day}`;
  const localMidnightUtc = Date.UTC(
    Number(local.year), Number(local.month) - 1, Number(local.day),
  ) - kolkataOffsetMs;
  const students = await User.find({ role: 'student' })
    .select('_id fullName')
    .lean();
  if (!students.length) return;

  const studentIds = students.map(({ _id }) => _id);
  const [notesToday, alreadyNotified] = await Promise.all([
    JournalNote.distinct('owner', {
      owner: { $in: studentIds },
      createdAt: { $gte: new Date(localMidnightUtc), $lte: now },
    }),
    Notification.distinct('recipient', {
      type: 'student_check_in',
      dedupeKey: { $in: studentIds.map((id) => `student-check-in:${id}:${dayKey}`) },
    }),
  ]);
  const excluded = new Set([...notesToday, ...alreadyNotified].map(String));
  const entries = students
    .filter(({ _id }) => !excluded.has(String(_id)))
    .map((student) => {
      const firstName = student.fullName?.trim().split(/\s+/)[0] || 'there';
      return notificationEntry({
        recipient: String(student._id),
        actorName: 'MindGrow',
        actorRole: 'system',
        type: 'student_check_in',
        title: 'Your evening check-in',
        body: `Hi ${firstName}, what happened today? How are you feeling? Add a short note when you are ready.`,
        payload: { destination: 'student_check_in' },
        dedupeKey: `student-check-in:${student._id}:${dayKey}`,
      });
    });
  await createNotifications(entries);
}
