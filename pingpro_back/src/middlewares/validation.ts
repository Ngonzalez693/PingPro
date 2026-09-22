/**
 * Validación de entrada en el borde del sistema.
 *
 * validateBody es una factory: recibe un esquema Joi y devuelve el middleware.
 * Así las rutas se leen como `validateBody(exerciseSchema)` y los controllers
 * pueden asumir que req.body ya tiene la forma correcta, con los valores por
 * defecto del esquema ya puestos.
 *
 * Los esquemas viven en utils/*.validator.ts.
 */
import { Request, Response, NextFunction } from 'express';
import { Schema } from 'joi';

// Validate body for JSON
export const validateBody = (schema: Schema) => (
  req: Request, res: Response, next: NextFunction
) => {
  const { error, value } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  // El valor validado y no el original: sin esto, los defaults del esquema
  // (p. ej. el ownZone de cada paso) no llegarían al controller.
  req.body = value;
  next();
};
