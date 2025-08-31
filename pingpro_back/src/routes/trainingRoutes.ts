// Training Routes
import { Router } from 'express';
import TrainingController from '@controllers/TrainingController';
import { validateBody } from '@middlewares/validation';
import { trainingSchema } from '@utils/training.validator';

const router = Router();

router.get('/', TrainingController.getAll);
router.get('/:id', TrainingController.getById);
router.post('/', validateBody(trainingSchema), TrainingController.create);
router.put('/:id', validateBody(trainingSchema), TrainingController.update);
router.delete('/:id', TrainingController.delete);

export default router;
