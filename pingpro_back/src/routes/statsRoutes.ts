/**
 * Rutas de estadísticas (montadas en /api/stats). Solo lectura y solo sobre
 * el usuario del token.
 */
import { Router } from 'express';
import StatsController from '../controllers/StatsController';
import authMiddleware from '../middlewares/authMiddleware';
import { validateQuery } from '../middlewares/validation';
import { statsEventsQuerySchema } from '../utils/stats.validator';

const router = Router();

router.use(authMiddleware);

router.get('/me/events', validateQuery(statsEventsQuerySchema), StatsController.myEvents);

export default router;
