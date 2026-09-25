import dns from 'node:dns';
import mongoose from 'mongoose';
import { config } from './config.js';
import { User } from '../models/users.js';
import { JournalNote } from '../models/journal-notes.js';
import { GrowthFeedback } from '../models/growth-feedback.js';
import { GrowthConnectionInvite } from '../models/growth-connection-invite.js';

export async function connectDatabase() {
  dns.setServers(config.mongodbDnsServers);
  await mongoose.connect(config.mongodbUri, {
    serverSelectionTimeoutMS: 5_000,
    autoIndex: false,
  });
  await Promise.all([
    User.createIndexes(),
    JournalNote.createIndexes(),
    GrowthFeedback.createIndexes(),
    GrowthConnectionInvite.createIndexes(),
  ]);
  console.log('MongoDB connected');
}

export async function disconnectDatabase() {
  await mongoose.disconnect();
}
