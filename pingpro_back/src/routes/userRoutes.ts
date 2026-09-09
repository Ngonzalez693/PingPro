/**
 * Rutas de usuarios (montadas en /api/users).
 *
 * El documento users/{uid} se crea desde AuthController al registrarse, no
 * desde aquí: por eso POST '/' está bloqueado a propósito en el controller.
 */
import { Router } from 'express';
import UserController from '@controllers/UserController';
import { validateBody } from '@middlewares/validation';
import { userSchema, userUpdateSchema } from '@/utils/user.validator';
import authMiddleware from '@/middlewares/authMiddleware';
import { requireSelfOrRole } from '@/middlewares/roleMiddleware';
import { USER_ROLES } from '@utils/constants';

const router = Router();

// Ninguna operación sobre usuarios es pública.
router.use(authMiddleware);

// Debe ir ANTES que '/:id': Express resuelve en orden de declaración y si no,
// /api/users/me entra por getById con id="me".
router.get('/me', UserController.getMe);

// No existe un listado de usuarios a propósito: exponía el correo de todos.
// Si algún día hace falta un panel de administración, se reañade con
// requireRole(USER_ROLES.ADMIN) desde el principio.

// Cada quien solo puede ver, editar o borrar su propia cuenta; el admin, cualquiera.
router.get('/:id', requireSelfOrRole(USER_ROLES.ADMIN), UserController.getById);
router.post('/', validateBody(userSchema), UserController.create); // Opcional o bloqueado
router.put('/:id', requireSelfOrRole(USER_ROLES.ADMIN), validateBody(userUpdateSchema), UserController.update);
router.delete('/:id', requireSelfOrRole(USER_ROLES.ADMIN), UserController.delete);

export default router;
