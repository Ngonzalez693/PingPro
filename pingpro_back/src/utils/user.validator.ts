import Joi from 'joi';

export const userSchema = Joi.object({
  uid: Joi.string().required(),
  email: Joi.string().email().required(),
  passwordHash: Joi.string().min(10).required(),
  displayName: Joi.string().optional(),
  photoURL: Joi.string().uri().optional(),
  roles: Joi.array().items(Joi.string()).optional(),
});
