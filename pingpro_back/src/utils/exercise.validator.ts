import Joi from 'joi';

// Info to validate exercises
export const exerciseSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().required(),
  image: Joi.string().uri().required(),
  isFavorite: Joi.boolean().optional(),
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
