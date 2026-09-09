/**
 * Esquema Joi de una estadística.
 *
 * userId no aparece a propósito: lo inyecta StatsService desde el token.
 *
 * Nota: la ampliación de Request que hay al final de este archivo está
 * duplicada en types/express.d.ts, que es donde corresponde. Aquí sobra.
 */
import Joi from 'joi';
import { IUserStat } from '../interfaces/models/IUserStat';

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