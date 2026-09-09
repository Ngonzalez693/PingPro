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

router.get('/', UserController.getAll);
router.get('/:id', UserController.getById);
router.post('/', validateBody(userSchema), UserController.create); // Opcional o bloqueado
router.put('/:id', validateBody(userSchema), UserController.update);
router.delete('/:id', UserController.delete);
// BUG conocido: al estar declarada DESPUÉS de '/:id', esta ruta nunca se
// alcanza — Express resuelve /api/users/me como getById con id="me".
// Debe subirse por encima de '/:id'. Ver AuthService.fetchUserProfile() en la app.
router.get('/me', authMiddleware, UserController.getMe);

export default router;
