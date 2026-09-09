/**
 * Rutas de autenticación (montadas en /api/auth).
 *
 * Solo el registro pasa por el backend: el Admin SDK crea el usuario en
 * Firebase Auth y su documento en Firestore de una sola vez. El login lo hace
 * la app directamente contra Firebase Auth, sin tocar el backend.
 */
import { Router } from 'express';
import AuthController from '@controllers/AuthController';
import { validateBody } from '@middlewares/validation';
import { signUpSchema } from '@utils/auth.validator';

const router = Router();

router.post('/signup', validateBody(signUpSchema), AuthController.signUp);
router.post('/verify', AuthController.verifyToken);

export default router;
