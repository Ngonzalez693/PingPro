/**
 * Rutas de entrenamientos (montadas en /api/trainings).
 *
 * Un entrenamiento es una lista ordenada de ids de ejercicios (exerciseIds).
 * /me/list devuelve el catálogo ya cruzado con el progreso del usuario, que es
 * lo que consume TrainingsState en la app.
 */
// Training Routes
import { Router } from 'express';
import TrainingController from '@controllers/TrainingController';
import { validateBody } from '@middlewares/validation';
import { trainingSchema } from '@utils/training.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();

// Las rutas '/me/*' van antes que '/:id' para que Express no lea "me" como id.
router.get('/me/list', authMiddleware, TrainingController.listWithUserState);
router.get('/me/states', authMiddleware, TrainingController.myStates);
router.post('/:id/completed', authMiddleware, TrainingController.completed);

router.get('/', TrainingController.getAll);
router.get('/:id', TrainingController.getById);
router.post('/', validateBody(trainingSchema), TrainingController.create);
router.put('/:id', validateBody(trainingSchema), TrainingController.update);
router.delete('/:id', TrainingController.delete);

export default router;
