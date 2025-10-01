import Joi from 'joi';
import { IUserStat } from '@interfaces/models/IUserStat';

export const statsSchema = Joi.object({
  id: Joi.string().optional(),
  exerciseCount: Joi.number().integer().min(0).required(),
  trainingCount: Joi.number().integer().min(0).required(),
  timestamp: Joi.date().iso().optional()
});

declare module 'express-serve-static-core' {
  interface Request {
    user?: { uid: string };
  }
}