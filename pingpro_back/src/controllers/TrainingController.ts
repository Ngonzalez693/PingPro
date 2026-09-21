/**
 * Controlador de entrenamientos. Mismo patrón que ExerciseController:
 * traduce HTTP ↔ TrainingService y no contiene reglas de negocio.
 *
 * listWithUserState es el endpoint que realmente usa la app: entrega el
 * catálogo ya cruzado con el progreso del usuario en una sola llamada.
 */
import { Request, Response, NextFunction } from 'express';
import { services } from '../container';
import { success, error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';

const service = services.trainings;

export default class TrainingController {
  // Get all exercises from service
  //
  // Como en ExerciseController: el listado es el catálogo más lo privado de
  // quien pregunta, así que hace falta el uid del token.
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const uid = req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const trainings = await service.getAll(uid);
      return success(res, trainings, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Get exercises by id from service
  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const uid = req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const training = await service.getById(req.params.id, uid);
      return success(res, training, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Create exercise from service
  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const id = await service.create(req.body);
      return success(res, { id }, HTTP_STATUS.CREATED);
    } catch (err) {
      const status = (err as { status?: number }).status ?? HTTP_STATUS.INTERNAL_ERROR;
      return error(res, (err as Error).message, status);
    }
  }

  // Update exercise from service
  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      await service.update(req.params.id, req.body);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Delete exercise from service
  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await service.delete(req.params.id);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Completar entrenamiento por usuario
  static async completed(req: Request, res: Response, _next: NextFunction) {
    try {
      // uid del authMiddleware (usa el que estés populando)
      const uid = (req as any).user?.uid || (req as any).uid || (req as any).userId || (req as any).auth?.uid;
      if (!uid) return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);

      const { id } = req.params;
      const completed = req.body?.completed ?? true;
      const state = await service.setCompletedForUser(uid, id, !!completed);
      return success(res, state, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Obtener todos los estados del usuario
  static async myStates(req: Request, res: Response, _next: NextFunction) {
    try {
      const uid = (req as any).user?.uid || (req as any).uid || (req as any).userId || (req as any).auth?.uid;
      if (!uid) return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      const states = await service.getUserTrainingStates(uid);
      return success(res, states, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async listWithUserState(req: Request, res: Response, _next: NextFunction) {
    try {
      const uid = (req as any).user?.uid || (req as any).uid || (req as any).userId || req.user?.uid;
      if (!uid) return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);

      const data = await service.getAllWithUserState(uid);
      return success(res, data, HTTP_STATUS.OK);
    } catch (err: any) {
      return error(res, err.message, err.status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }
}
