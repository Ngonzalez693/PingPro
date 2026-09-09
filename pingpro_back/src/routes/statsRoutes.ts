/**
 * Rutas de estadísticas (montadas en /api/stats).
 *
 * Todas las estadísticas viven en users/{uid}/stats, así que el router entero
 * exige token: el uid nunca llega por la URL, siempre sale de req.user.
 */
// Stats Routes
import { Router } from 'express';
import StatsController from '@controllers/StatsController';
import { validateBody } from '@middlewares/validation';
import { statsSchema } from '@/utils/stats.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();
router.use(authMiddleware);   // aplica a todas las rutas de abajo

router.get('/', StatsController.getAll);
router.get('/:id', StatsController.getById);
router.post('/', validateBody(statsSchema), StatsController.createOrUpdate);

export default router;
