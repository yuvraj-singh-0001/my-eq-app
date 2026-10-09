import mongoose from 'mongoose';
import { Notification } from '../../models/notification.js';
import { createHttpError } from '../auth/auth.helpers.js';

function notificationData(item) {
  return {
    id: item._id.toString(),
    type: item.type,
    title: item.title,
    body: item.body,
    actorName: item.actorName,
    actorRole: item.actorRole,
    payload: item.payload ?? {},
    readAt: item.readAt,
    createdAt: item.createdAt,
  };
}

export async function listNotifications(request, response) {
  const [items, unreadCount] = await Promise.all([
    Notification.find({ recipient: request.auth.sub })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean(),
    Notification.countDocuments({ recipient: request.auth.sub, readAt: null }),
  ]);
  return response.json({
    success: true,
    data: { notifications: items.map(notificationData), unreadCount },
  });
}

export async function markNotificationRead(request, response) {
  if (!mongoose.isValidObjectId(request.params.notificationId)) {
    throw createHttpError(400, 'That notification is invalid.');
  }
  const item = await Notification.findOneAndUpdate(
    { _id: request.params.notificationId, recipient: request.auth.sub },
    { $set: { readAt: new Date() } },
    { new: true },
  ).lean();
  if (!item) throw createHttpError(404, 'This notification could not be found.');
  return response.json({ success: true, data: { notification: notificationData(item) } });
}

export async function markAllNotificationsRead(request, response) {
  await Notification.updateMany(
    { recipient: request.auth.sub, readAt: null },
    { $set: { readAt: new Date() } },
  );
  return response.json({ success: true, data: { updated: true } });
}
