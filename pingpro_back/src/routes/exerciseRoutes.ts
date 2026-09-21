/**
 * Rutas del catálogo de ejercicios (montadas en /api/exercises).
 *
 * Tres grupos distintos:
 *  - Catálogo compartido (/, /:id): lo lee cualquiera con sesión, lo escribe
 *    solo un admin.
 *  - Ejercicios propios (/me, /me/:id): cualquiera con sesión, y siempre sobre
 *    los suyos. Quién es el dueño sale del token.
 *  - Estado por usuario (/me/states, /:id/favorite, /:id/completed): requiere
 *    authMiddleware porque escribe en users/{uid}/exerciseStates.
 *
 * Quién puede hacer qué se decide aquí, con requireRole, y no dentro de los
 * servicios: así se lee de un vistazo en un solo archivo.
 */
// Exercise Routes
import { Router } from 'express';
import ExerciseController from '../controllers/ExerciseController';
import { validateBody } from '../middlewares/validation';
import { favoriteSchema, completedSchema } from '../utils/exerciseState.validator';
import { exerciseSchema } from '../utils/exercise.validator';
import authMiddleware from '../middlewares/authMiddleware';
import { requireRole } from '../middlewares/roleMiddleware';
import { USER_ROLES } from '../utils/constants';

const router = Router();

// El catálogo no es público: toda la ruta exige sesión.
router.use(authMiddleware);

// Todo lo de '/me' va antes que '/:id': si no, Express interpretaría "me" como
// un id de ejercicio.
router.get('/me/states', ExerciseController.myStates);

// Ejercicios propios: sin requireRole, porque cualquiera puede crear los suyos.
// El uid del token es el dueño y el servicio no deja salir de ahí.
router.post('/me', validateBody(exerciseSchema), ExerciseController.createMine);
router.put('/me/:id', validateBody(exerciseSchema), ExerciseController.updateMine);
router.delete('/me/:id', ExerciseController.deleteMine);

router.get('/', ExerciseController.getAll);
router.get('/:id', ExerciseController.getById);

// El catálogo es contenido curado: cualquiera con sesión puede leerlo, pero
// solo un admin puede modificarlo.
router.post('/', requireRole(USER_ROLES.ADMIN), validateBody(exerciseSchema), ExerciseController.create);
router.put('/:id', requireRole(USER_ROLES.ADMIN), validateBody(exerciseSchema), ExerciseController.update);
router.delete('/:id', requireRole(USER_ROLES.ADMIN), ExerciseController.delete);

router.post('/:id/favorite', validateBody(favoriteSchema), ExerciseController.favorite);
router.post('/:id/completed', validateBody(completedSchema), ExerciseController.completed);

export default router;
