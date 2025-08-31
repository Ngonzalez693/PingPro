// Exercise Routes
import { Router } from 'express';
import ExerciseController from '@controllers/ExerciseController';
import { validateBody } from '@middlewares/validation';
import { exerciseSchema } from '@utils/exercise.validator';

const router = Router();

router.get('/', ExerciseController.getAll);
router.get('/:id', ExerciseController.getById);
router.post('/', validateBody(exerciseSchema), ExerciseController.create);
router.put('/:id', validateBody(exerciseSchema), ExerciseController.update);
router.delete('/:id', ExerciseController.delete);

export default router;
