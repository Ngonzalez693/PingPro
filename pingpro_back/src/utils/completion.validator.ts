/**
 * Cuerpo de POST /:id/completed, común a ejercicios y entrenamientos.
 *
 * completed es opcional con default true: POST sin body marca como hecho, que
 * es el caso normal desde la app. session es la sesión del día (1..3) que el
 * usuario eligió; la app vieja no la envía y queda como "sin sesión".
 */
import Joi from 'joi';

export const completedSchema = Joi.object({
  completed: Joi.boolean().optional().default(true),
  session: Joi.number().integer().min(1).max(3).allow(null).optional(),
});
