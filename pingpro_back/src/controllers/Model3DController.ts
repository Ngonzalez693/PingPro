/**
 * Controlador del catálogo de modelos 3D (solo lectura).
 *
 * Ojo con la inconsistencia: a diferencia del resto de controllers, este
 * responde el JSON crudo en lugar de envolverlo con success()/error(), por lo
 * que el cliente recibe un array pelado y no { success, data }.
 * Model3dCatalog en la app depende de esa forma. Los errores sí pasan por
 * errorHandler (next(err)), para no enseñar el mensaje interno.
 */
import { Request, Response, NextFunction } from 'express';
import { services } from '../container';

const service = services.models3d;

export default class Model3DController {
  static async list(_req: Request, res: Response, next: NextFunction) {
    try {
      const data = await service.list();
      return res.json(data);
    } catch (err) {
      return next(err);
    }
  }

  static async get(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const doc = await service.get(id);
      if (!doc) return res.status(404).json({ message: 'Model3D no encontrado' });
      return res.json(doc);
    } catch (err) {
      return next(err);
    }
  }
}
