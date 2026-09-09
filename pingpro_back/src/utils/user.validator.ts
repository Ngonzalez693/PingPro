/**
 * Esquema Joi del perfil de usuario, usado en POST y PUT /api/users.
 *
 * Desalineado con el modelo: exige `uid`, pero IUser usa `id` y el body que
 * envía la app no trae ninguno de los dos. Hoy PUT /api/users/:id rechaza
 * cuerpos válidos por esto.
 */
import Joi from 'joi';

export const userSchema = Joi.object({
  uid: Joi.string().required(),
  email: Joi.string().email().required(),
  displayName: Joi.string().optional(),
  photoURL: Joi.string().uri().optional(),
  roles: Joi.array().items(Joi.string()).optional(),
});
