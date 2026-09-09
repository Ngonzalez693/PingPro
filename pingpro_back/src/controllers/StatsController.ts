/**
 * Controlador de estadísticas.
 *
 * El uid sale siempre de req.user (token), nunca de la URL: así un usuario no
 * puede pedir las estadísticas de otro. La ruta entera exige authMiddleware,
 * de ahí el `req.user!`.
 *
 * Nota: hoy la app calcula las gráficas en el cliente a partir de los
 * completedAt de ejercicios y entrenamientos, así que estos endpoints están
 * implementados pero sin consumir.
 */
import { Request, Response, NextFunction } from 'express';
import { StatsService } from '../services/StatsService';
import { success, error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';

const service = new StatsService();

export default class StatsController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const stats = await service.getAllForUser(req.user!.uid);
      return success(res, stats, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async createOrUpdate(req: Request, res: Response, next: NextFunction) {
    try {
      const dto = req.body;
      const stat = await service.createOrUpdate(req.user!.uid, dto);
      return success(res, stat, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const stat = await service.getById(req.user!.uid, req.params.id);
      return success(res, stat, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }
}
