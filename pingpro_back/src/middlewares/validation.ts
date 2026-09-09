/**
 * Validación de entrada en el borde del sistema.
 *
 * validateBody es una factory: recibe un esquema Joi y devuelve el middleware.
 * Así las rutas se leen como `validateBody(exerciseSchema)` y los controllers
 * pueden asumir que req.body ya tiene la forma correcta.
 *
 * Los esquemas viven en utils/*.validator.ts.
 */
import { Request, Response, NextFunction } from 'express';
import { Schema } from 'joi';

// Validate body for JSON
export const validateBody = (schema: Schema) => (
  req: Request, res: Response, next: NextFunction
) => {
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};
