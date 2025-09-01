import Joi from 'joi';

export const signUpSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  displayName: Joi.string().optional().allow(''),
});

export const verifySchema = Joi.object({
  // la verificación sólo usa la cabecera, así que no validas body aquí
});
