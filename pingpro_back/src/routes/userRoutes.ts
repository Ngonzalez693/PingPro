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
router.get('/me', authMiddleware, UserController.getMe);

export default router;
