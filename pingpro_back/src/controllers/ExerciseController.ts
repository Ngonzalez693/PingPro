import { Request, Response, NextFunction } from 'express';
import { ExerciseService } from '@services/ExerciseService';
import { success, error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';

const service = new ExerciseService();    // Object type service

export default class ExerciseController {
  // Get all exercises from service
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const exercises = await service.getAll();
      return success(res, exercises, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Get exercises by id from service
  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const exercise = await service.getById(req.params.id);
      return success(res, exercise, HTTP_STATUS.OK);
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
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
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

  // Set exercise as favorite or not
  static async favorite(req: Request, res: Response, _next: NextFunction) {
    try {
      // uid viene del authMiddleware que ya activaste
      const uid = (req as any).user?.uid || req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const { id } = req.params;
      // si no envían body, default true
      const isFavorite = req.body?.isFavorite ?? true;

      const state = await service.setFavoriteForUser(uid, id, !!isFavorite);
      return success(res, state, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Mark exercise as completed or not
  static async completed(req: Request, res: Response, _next: NextFunction) {
    try {
      const uid = (req as any).user?.uid || req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const { id } = req.params;
      const completed = req.body?.completed ?? true;

      const state = await service.setCompletedForUser(uid, id, !!completed);
      return success(res, state, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  // Obtener TODOS los estados del usuario autenticado
  static async myStates(req: Request, res: Response, _next: NextFunction) {
    try {
      const uid = (req as any).user?.uid || req.user?.uid;
      if (!uid) {
        return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);
      }

      const states = await service.getUserExerciseStates(uid);
      return success(res, states, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }
}
