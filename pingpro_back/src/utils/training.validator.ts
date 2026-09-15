/**
 * Esquema Joi de un entrenamiento. Exige al menos un ejercicio en exerciseIds:
 * un entrenamiento vacío no tendría sentido en la pantalla de detalle. Que esos
 * ejercicios existan lo comprueba TrainingService, porque hace falta leer la
 * base de datos. La categoría tiene que ser una de TRAINING_CATEGORIES.
 */
import Joi from 'joi';
import { TRAINING_CATEGORIES } from './constants';

// Info to validate trainings
export const trainingSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().valid(...TRAINING_CATEGORIES).required(),
  image: Joi.string().required(),
  description: Joi.string().allow('').optional(),
  exerciseIds: Joi.array().items(Joi.string()).min(1).required(),
  duration: Joi.number().integer().min(0).optional(),
});
