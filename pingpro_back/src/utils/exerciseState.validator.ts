/**
 * Esquema de la acción de favorito sobre un ejercicio.
 *
 * isFavorite es opcional con default true: así POST /:id/favorite sin body
 * marca como favorito, que es el caso normal desde la app. El de completado
 * vive en completion.validator.ts porque lo comparten los entrenamientos.
 */
import Joi from 'joi';

export const favoriteSchema = Joi.object({
  isFavorite: Joi.boolean().optional().default(true),
});
