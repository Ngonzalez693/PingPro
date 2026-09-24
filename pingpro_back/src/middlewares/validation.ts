/**
 * Validación de entrada en el borde del sistema.
 *
 * validateBody y validateQuery son factories: reciben un esquema Joi y
 * devuelven el middleware. Así las rutas se leen como
 * `validateBody(exerciseSchema)` y los controllers pueden asumir que el valor
 * ya tiene la forma correcta, con los valores por defecto del esquema puestos.
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

// Igual que validateBody, para la query string. El valor validado va a
// res.locals.query y no a req.query: Joi convierte los tipos (p. ej. `from` a
// Date) y eso no cabe en el tipo de req.query.
export const validateQuery = (schema: Schema) => (
  req: Request, res: Response, next: NextFunction
) => {
  const { error, value } = schema.validate(req.query);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  res.locals.query = value;
  next();
};
