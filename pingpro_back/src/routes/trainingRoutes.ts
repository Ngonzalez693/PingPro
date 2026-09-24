/**
 * Rutas de entrenamientos (montadas en /api/trainings).
 *
 * Un entrenamiento es una lista ordenada de ids de ejercicios (exerciseIds).
 * /me/list devuelve el catálogo ya cruzado con el progreso del usuario, que es
 * lo que consume TrainingsState en la app.
 */
// Training Routes
import { Router } from 'express';
import TrainingController from '../controllers/TrainingController';
import { validateBody } from '../middlewares/validation';
import { trainingSchema } from '../utils/training.validator';
import { completedSchema } from '../utils/completion.validator';
import authMiddleware from '../middlewares/authMiddleware';
import { requireRole } from '../middlewares/roleMiddleware';
import { USER_ROLES } from '../utils/constants';

const router = Router();

// El catálogo no es público: toda la ruta exige sesión.
router.use(authMiddleware);

// Las rutas '/me/*' van antes que '/:id' para que Express no lea "me" como id.
router.get('/me/list', TrainingController.listWithUserState);
router.get('/me/states', TrainingController.myStates);

// Entrenamientos propios: sin requireRole. El dueño sale del token, y sus
// ejercicios se validan contra lo que ese dueño ve (catálogo + los suyos).
router.post('/me', validateBody(trainingSchema), TrainingController.createMine);
router.put('/me/:id', validateBody(trainingSchema), TrainingController.updateMine);
router.delete('/me/:id', TrainingController.deleteMine);

router.post('/:id/completed', validateBody(completedSchema), TrainingController.completed);

router.get('/', TrainingController.getAll);
router.get('/:id', TrainingController.getById);

// Igual que en ejercicios: lectura para cualquier sesión, escritura solo admin.
router.post('/', requireRole(USER_ROLES.ADMIN), validateBody(trainingSchema), TrainingController.create);
router.put('/:id', requireRole(USER_ROLES.ADMIN), validateBody(trainingSchema), TrainingController.update);
router.delete('/:id', requireRole(USER_ROLES.ADMIN), TrainingController.delete);

export default router;
