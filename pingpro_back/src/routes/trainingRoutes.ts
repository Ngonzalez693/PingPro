// Training Routes
import { Router } from 'express';
import TrainingController from '@controllers/TrainingController';
import { validateBody } from '@middlewares/validation';
import { trainingSchema } from '@utils/training.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();

router.get('/me/list', authMiddleware, TrainingController.listWithUserState);
router.get('/me/states', authMiddleware, TrainingController.myStates);
router.post('/:id/completed', authMiddleware, TrainingController.completed);

router.get('/', TrainingController.getAll);
router.get('/:id', TrainingController.getById);
router.post('/', validateBody(trainingSchema), TrainingController.create);
router.put('/:id', validateBody(trainingSchema), TrainingController.update);
router.delete('/:id', TrainingController.delete);

export default router;
