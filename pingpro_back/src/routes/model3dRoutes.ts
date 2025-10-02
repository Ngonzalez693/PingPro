import { Router } from 'express';
import Model3DController from '@/controllers/Model3DController';

const router = Router();

router.get('/', Model3DController.list);
router.get('/:id', Model3DController.get);

export default router;
