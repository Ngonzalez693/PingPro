import { Response } from 'express';

// Success response
export const success = (res: Response, data: any, status = 200) =>
  res.status(status).json({ success: true, data });

// Error response
export const error = (res: Response, message: string, status = 500) =>
  res.status(status).json({ success: false, message });
