import dns from 'node:dns';
import mongoose from 'mongoose';
import { config } from './config.js';

export async function connectDatabase() {
  dns.setServers(config.mongodbDnsServers);
  await mongoose.connect(config.mongodbUri, {
    serverSelectionTimeoutMS: 5_000,
  });
  console.log('MongoDB connected');
}

export async function disconnectDatabase() {
  await mongoose.disconnect();
}
