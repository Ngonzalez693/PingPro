// Routes Barrel
import { Router } from 'express';
import exerciseRoutes from './exerciseRoutes';
import trainingRoutes from './trainingRoutes';
import userRoutes from './userRoutes';
import authRoutes from './authRoutes';
import statsRoutes from './statsRoutes';
import model3dRoutes from './model3dRoutes';

const router = Router();

router.use('/exercises', exerciseRoutes);
router.use('/trainings', trainingRoutes);
router.use('/users', userRoutes);
router.use('/auth', authRoutes);
router.use('/stats', statsRoutes);
router.use('/model3d', model3dRoutes);

export default router;
