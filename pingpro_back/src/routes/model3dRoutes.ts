import { Router } from 'express';
import Model3DController from '@/controllers/Model3DController';
import multer from 'multer';

const router = Router();
const uploadMiddleware = multer({ dest: 'uploads/' });

router.get('/', Model3DController.list);
router.post(
  '/upload',
  uploadMiddleware.single('file'),
  Model3DController.upload
);

export default router;