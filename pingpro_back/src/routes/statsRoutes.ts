// Stats Routes
import { Router } from 'express';
import StatsController from '@controllers/StatsController';
import { validateBody } from '@middlewares/validation';
import { statsSchema } from '@/utils/stats.validator';
import authMiddleware from '@/middlewares/authMiddleware';

const router = Router();
router.use(authMiddleware);

router.get('/', StatsController.getAll);
router.get('/:id', StatsController.getById);
router.post('/', validateBody(statsSchema), StatsController.createOrUpdate);

export default router;
