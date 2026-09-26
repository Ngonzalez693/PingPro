/**
 * Controlador de estadísticas: traduce HTTP ↔ StatsService. Siempre sobre el
 * usuario del token; no hay forma de pedir las de otro.
 */
import { Request, Response, NextFunction } from 'express';
import { services } from '../container';
import { success, error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';

const service = services.stats;

export default class StatsController {
  // `from` llega ya validado y convertido a Date por validateQuery.
  static async myEvents(req: Request, res: Response, next: NextFunction) {
    try {
      const uid = req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const events = await service.getEvents(uid, res.locals.query.from as Date);
      return success(res, events, HTTP_STATUS.OK);
    } catch (err) {
      return next(err);
    }
  }
}
