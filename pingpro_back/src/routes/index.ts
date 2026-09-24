/**
 * Barrel de rutas: agrupa los routers por recurso y los monta bajo el prefijo
 * que app.ts define (/api). El nombre del segmento aquí define la URL pública.
 */
// Routes Barrel
import { Router } from 'express';
import exerciseRoutes from './exerciseRoutes';
import trainingRoutes from './trainingRoutes';
import userRoutes from './userRoutes';
import authRoutes from './authRoutes';
import model3dRoutes from './model3dRoutes';
import statsRoutes from './statsRoutes';

const router = Router();

router.use('/exercises', exerciseRoutes);
router.use('/trainings', trainingRoutes);
router.use('/users', userRoutes);
router.use('/auth', authRoutes);
router.use('/model3d', model3dRoutes);
router.use('/stats', statsRoutes);

export default router;
