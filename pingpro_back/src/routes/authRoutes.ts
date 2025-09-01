import { Router } from 'express';
import AuthController from '@controllers/AuthController';
import { validateBody } from '@middlewares/validation';
import { signUpSchema } from '@utils/auth.validator';

const router = Router();

router.post('/signup', validateBody(signUpSchema), AuthController.signUp);
router.post('/verify', AuthController.verifyToken);

export default router;
