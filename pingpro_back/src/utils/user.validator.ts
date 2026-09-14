/**
 * Esquema Joi de POST /api/users. Esa ruta está bloqueada a propósito
 * (UserController.create responde 400: los perfiles solo se crean en el
 * registro), así que este esquema no se usa con datos reales. PUT
 * /api/users/:id usa userUpdateSchema, más abajo.
 */
import Joi from 'joi';

export const userSchema = Joi.object({
  uid: Joi.string().required(),
  email: Joi.string().email().required(),
  displayName: Joi.string().optional(),
  photoURL: Joi.string().uri().optional(),
  roles: Joi.array().items(Joi.string()).optional(),
});

/**
 * Esquema de PUT /api/users/:id.
 *
 * Solo deja tocar displayName y photoURL. Es deliberado que NO incluya:
 *   - `roles`: un usuario puede editar su propia cuenta, así que aceptarlo sería
 *     escalada de privilegios directa (mandarse `roles: ['admin']`).
 *   - `email`: la fuente de verdad es Firebase Auth; permitir cambiarlo aquí
 *     dejaría el documento de Firestore desincronizado de la credencial.
 *
 * Joi rechaza claves desconocidas por defecto, así que enviar cualquiera de las
 * dos devuelve 400 en vez de ignorarlas en silencio.
 */
export const userUpdateSchema = Joi.object({
  displayName: Joi.string().min(1).max(60).optional(),
  photoURL: Joi.string().uri().optional(),
}).min(1); // un body vacío no es una actualización válida
