import { Request, Response, NextFunction } from 'express';

interface HttpError extends Error {
  status?: number;
}

export default function errorHandler(
  err: HttpError,
  req: Request,
  res: Response,
  next: NextFunction
) {
  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';
  res.status(status).json({ error: message });
}
