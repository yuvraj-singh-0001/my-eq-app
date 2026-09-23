import 'dotenv/config';
import { z } from 'zod';

const environmentSchema = z.object({
  PORT: z.coerce.number().int().positive().default(4000),
  API_BASE_URL: z.string().url().default('http://localhost:4000/api'),
  MONGODB_URI: z.string().min(1),
  MONGODB_DNS_SERVERS: z.string().default('1.1.1.1,8.8.8.8'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  CORS_ORIGINS: z.string().default(''),
  BCRYPT_ROUNDS: z.coerce.number().int().min(10).max(14).default(12),
});

const result = environmentSchema.safeParse(process.env);
if (!result.success) {
  console.error('Invalid environment configuration:', result.error.flatten().fieldErrors);
  process.exit(1);
}

const values = result.data;

export const config = {
  port: values.PORT,
  apiBaseUrl: values.API_BASE_URL,
  mongodbUri: values.MONGODB_URI,
  mongodbDnsServers: values.MONGODB_DNS_SERVERS.split(',').map((server) => server.trim()).filter(Boolean),
  jwtSecret: values.JWT_SECRET,
  jwtExpiresIn: values.JWT_EXPIRES_IN,
  bcryptRounds: values.BCRYPT_ROUNDS,
  corsOrigins: values.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean),
};
