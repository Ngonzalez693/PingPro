/**
 * Esquema Joi de un entrenamiento. Exige al menos un ejercicio en exerciseIds:
 * un entrenamiento vacío no tendría sentido en la pantalla de detalle.
 */
import Joi from 'joi';

// Info to validate trainings
export const trainingSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().required(),
  image: Joi.string().required(),
  description: Joi.string().allow('').optional(),
  exerciseIds: Joi.array().items(Joi.string()).min(1).required(),
  duration: Joi.number().integer().min(0).optional(),
});
