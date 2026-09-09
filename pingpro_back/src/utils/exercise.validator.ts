/**
 * Esquema Joi de un ejercicio, usado por validateBody en exerciseRoutes.
 *
 * La secuencia exige al menos un paso y valida los cinco códigos como enteros
 * >= 1. Ojo: solo comprueba el mínimo, no el máximo de cada enum, así que un
 * hit: 99 pasaría la validación y luego el mapper 3D caería en el fallback.
 */
import Joi from 'joi';

// Info to validate exercises
export const exerciseSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().required(),
  image: Joi.string().required(),
  isFavorite: Joi.boolean().optional(),
  completedAt: Joi.date().optional().allow(null),
  description: Joi.string().allow('').optional(),
  sequence: Joi.array()
    .items(
      Joi.object({
        hit: Joi.number().integer().min(1).required(),
        rotation: Joi.number().integer().min(1).required(),
        zone: Joi.number().integer().min(1).required(),
        direction: Joi.number().integer().min(1).required(),
        side: Joi.number().integer().min(1).required(),
      })
    )
    .min(1)
    .required(),
});

export const updateExerciseSchema = exerciseSchema.keys({
  name: Joi.string().optional(),
});
  