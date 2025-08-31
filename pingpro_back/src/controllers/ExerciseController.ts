import { Request, Response, NextFunction } from 'express';
import { ExerciseService } from '@services/ExerciseService';
import { success, error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';

const service = new ExerciseService();

export default class ExerciseController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const exercises = await service.getAll();
      return success(res, exercises, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const exercise = await service.getById(req.params.id);
      return success(res, exercise, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const id = await service.create(req.body);
      return success(res, { id }, HTTP_STATUS.CREATED);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      await service.update(req.params.id, req.body);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await service.delete(req.params.id);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }
}
