// Exercise Routes
import { Router } from 'express';
import ExerciseController from '@controllers/ExerciseController';
import { validateBody } from '@middlewares/validation';
import { favoriteSchema, completedSchema } from '@/utils/exerciseState.validator';
import { exerciseSchema } from '@utils/exercise.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();

router.get('/me/states', authMiddleware, ExerciseController.myStates);

router.get('/', ExerciseController.getAll);
router.get('/:id', ExerciseController.getById);
router.post('/', validateBody(exerciseSchema), ExerciseController.create);
router.put('/:id', validateBody(exerciseSchema), ExerciseController.update);
router.delete('/:id', ExerciseController.delete);

router.post('/:id/favorite', authMiddleware, validateBody(favoriteSchema), ExerciseController.favorite);
router.post('/:id/completed', authMiddleware, validateBody(completedSchema), ExerciseController.completed);

export default router;
