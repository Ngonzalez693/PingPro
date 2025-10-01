import Joi from 'joi';

export const favoriteSchema = Joi.object({
  isFavorite: Joi.boolean().optional().default(true),
});

export const completedSchema = Joi.object({
  completed: Joi.boolean().optional().default(true),
});
