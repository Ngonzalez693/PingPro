import { Response } from 'express';

export const success = (res: Response, data: any, status = 200) =>
  res.status(status).json({ success: true, data });

export const error = (res: Response, message: string, status = 500) =>
  res.status(status).json({ success: false, message });
