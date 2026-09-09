/**
 * Rutas del catálogo de modelos 3D (montadas en /api/model3d).
 *
 * Cada documento es un par nombre → URL de un archivo .glb. La app los pide una
 * sola vez al abrir un ejercicio (Model3dCatalog) y luego resuelve por nombre
 * las animaciones que produce el mapper exercise_to_glb_steps.dart.
 *
 * Solo lectura: los .glb se suben por fuera de la API.
 */
import { Router } from 'express';
import Model3DController from '../controllers/Model3DController';
import authMiddleware from '../middlewares/authMiddleware';

const router = Router();

// Las URLs de los .glb no son públicas: toda la ruta exige sesión.
router.use(authMiddleware);

router.get('/', Model3DController.list);
router.get('/:id', Model3DController.get);

export default router;
