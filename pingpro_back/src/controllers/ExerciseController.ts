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
  static async favorite(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id;
      const { isFavorite } = req.body as { isFavorite: boolean };
      await service.setFavorite(id, isFavorite);
      return success(res, { id, isFavorite }, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.BAD_REQUEST);
    }
  }

  // Mark exercise as completed or not
  static async completed(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id;
      const { completed } = req.body as { completed: boolean };
      await service.setCompleted(id, completed);
      return success(res, { id, completed }, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.BAD_REQUEST);
    }
  }
}
