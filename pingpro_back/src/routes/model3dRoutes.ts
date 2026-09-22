/**
 * Rutas del catálogo de modelos 3D (montadas en /api/model3d).
 *
 * La app lee la fila 'PingPro Animations' para obtener la URL del único .glb
 * con todas las animaciones (Model3dCatalog), y dentro de ese archivo elige
 * los clips por nombre según lo que produce el mapper exercise_to_glb_steps.dart.
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
