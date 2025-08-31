import Joi from 'joi';

// Info to validate trainings
export const trainingSchema = Joi.object({
  name: Joi.string().required(),
  description: Joi.string().allow('').optional(),
  exerciseIds: Joi.array().items(Joi.string()).min(1).required(),
  duration: Joi.number().integer().min(0).optional(),
  tags: Joi.array().items(Joi.string()).optional(),
});
