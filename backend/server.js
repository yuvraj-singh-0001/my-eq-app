import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { config } from './src/config/config.js';
import { connectDatabase, disconnectDatabase } from './src/config/db.js';
import { router } from './src/routes/router.js';

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({
  origin: config.corsOrigins.length > 0 ? config.corsOrigins : true,
  credentials: true,
}));
app.use(express.json({ limit: '100kb' }));
app.use(express.urlencoded({ extended: false, limit: '100kb' }));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
}));

app.use('/api/auth', router);

app.use((_request, response) => {
  response.status(404).json({ success: false, message: 'Route not found' });
});

app.use((error, _request, response, _next) => {
  console.error(error);
  if (error.code === 11000) {
    const field = Object.keys(error.keyPattern ?? {})[0] ?? 'field';
    return response.status(409).json({
      success: false,
      message: `${field} is already registered`,
    });
  }

  const statusCode = error.statusCode ?? 500;
  return response.status(statusCode).json({
    success: false,
    message: statusCode === 500 ? 'Internal server error' : error.message,
  });
});

async function startServer() {
  await connectDatabase();

  const server = app.listen(config.port, () => {
    console.log(`MyEQ App backend running on port ${config.port}`);
  });

  const shutdown = async (signal) => {
    console.log(`${signal} received. Shutting down gracefully.`);
    server.close(async () => {
      await disconnectDatabase();
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

startServer().catch((error) => {
  console.error('Failed to start backend:', error);
  process.exit(1);
});
