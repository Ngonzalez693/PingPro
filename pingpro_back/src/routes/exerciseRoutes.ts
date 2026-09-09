/**
 * Rutas del catálogo de ejercicios (montadas en /api/exercises).
 *
 * Dos grupos distintos:
 *  - Catálogo compartido (/, /:id): igual para todos los usuarios.
 *  - Estado por usuario (/me/states, /:id/favorite, /:id/completed): requiere
 *    authMiddleware porque escribe en users/{uid}/exerciseStates.
 */
// Exercise Routes
import { Router } from 'express';
import ExerciseController from '@controllers/ExerciseController';
import { validateBody } from '@middlewares/validation';
import { favoriteSchema, completedSchema } from '@/utils/exerciseState.validator';
import { exerciseSchema } from '@utils/exercise.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();

// Va antes que '/:id': si no, Express interpretaría "me" como un id de ejercicio.
router.get('/me/states', authMiddleware, ExerciseController.myStates);

router.get('/', ExerciseController.getAll);
router.get('/:id', ExerciseController.getById);
router.post('/', validateBody(exerciseSchema), ExerciseController.create);
router.put('/:id', validateBody(exerciseSchema), ExerciseController.update);
router.delete('/:id', ExerciseController.delete);

router.post('/:id/favorite', authMiddleware, validateBody(favoriteSchema), ExerciseController.favorite);
router.post('/:id/completed', authMiddleware, validateBody(completedSchema), ExerciseController.completed);

export default router;
