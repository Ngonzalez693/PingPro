/**
 * Controlador del catálogo de modelos 3D (solo lectura).
 *
 * Ojo con la inconsistencia: a diferencia del resto de controllers, este
 * responde el JSON crudo en lugar de envolverlo con success()/error(), por lo
 * que el cliente recibe un array pelado y no { success, data }.
 * Model3dCatalog en la app depende de esa forma.
 */
import { Request, Response } from 'express';
import Model3DService from '../services/Model3DService';

const service = Model3DService.instance;

export default class Model3DController {
  static async list(_req: Request, res: Response) {
    try {
      const data = await service.list();
      return res.json(data);
    } catch (e: any) {
      return res.status(500).json({ message: 'Error listando Model3D', error: e?.message });
    }
  }

  static async get(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const doc = await service.get(id);
      if (!doc) return res.status(404).json({ message: 'Model3D no encontrado' });
      return res.json(doc);
    } catch (e: any) {
      return res.status(500).json({ message: 'Error obteniendo Model3D', error: e?.message });
    }
  }
}
