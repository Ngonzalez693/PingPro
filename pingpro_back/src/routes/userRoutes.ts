/**
 * Rutas de usuarios (montadas en /api/users).
 *
 * El documento users/{uid} se crea desde AuthController al registrarse, no
 * desde aquí: por eso POST '/' está bloqueado a propósito en el controller.
 */
import { Router } from 'express';
import UserController from '@controllers/UserController';
import { validateBody } from '@middlewares/validation';
import { userSchema } from '@/utils/user.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();

// Debe ir ANTES que '/:id': Express resuelve en orden de declaración y si no,
// /api/users/me entra por getById con id="me".
router.get('/me', authMiddleware, UserController.getMe);

router.get('/', UserController.getAll);
router.get('/:id', UserController.getById);
router.post('/', validateBody(userSchema), UserController.create); // Opcional o bloqueado
router.put('/:id', validateBody(userSchema), UserController.update);
router.delete('/:id', UserController.delete);

export default router;
