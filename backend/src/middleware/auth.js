import jwt from 'jsonwebtoken';
import { config } from '../config/config.js';
import { createHttpError } from '../controllers/auth/auth.helpers.js';

export function authenticate(request, _response, next) {
  const authorization = request.headers.authorization;
  const [scheme, token] = authorization?.split(' ') ?? [];

  if (scheme !== 'Bearer' || !token) {
    return next(createHttpError(401, 'Authorization token is required'));
  }

  try {
    request.auth = jwt.verify(token, config.jwtSecret);
    return next();
  } catch {
    return next(createHttpError(401, 'Invalid or expired authorization token'));
  }
}
