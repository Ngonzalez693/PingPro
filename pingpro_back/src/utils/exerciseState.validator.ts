/**
 * Esquemas de las acciones de estado por usuario sobre un ejercicio.
 *
 * Ambos campos son opcionales con default true: así POST /:id/favorite sin body
 * marca como favorito, que es el caso normal desde la app.
 */
import Joi from 'joi';

export const favoriteSchema = Joi.object({
  isFavorite: Joi.boolean().optional().default(true),
});

export const completedSchema = Joi.object({
  completed: Joi.boolean().optional().default(true),
});
