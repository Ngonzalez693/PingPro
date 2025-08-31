import { Request, Response, NextFunction } from 'express';

interface HttpError extends Error {
  status?: number;
}

// Error handler helper
export default function errorHandler(
  err: HttpError,
  req: Request,
  res: Response,
  next: NextFunction
) {
  console.error(err.stack);
  const status = err.status || 500;
  res.status(status).json({ success: false, message: err.message });
}
