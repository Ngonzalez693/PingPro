import { Request, Response, NextFunction } from 'express';
import Model3DService from '@/services/Model3DService';
import { success, error } from '@/utils/apiResponse';
import { HTTP_STATUS } from '@/utils/constants';

const service = new Model3DService();

export default class Model3DController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const models = await service.list();
      return success(res, models, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async upload(req: Request, res: Response, next: NextFunction) {
    try {
      const { name } = req.body;
      // req.file provided by multer
      const filePath = (req.file as any).path;
      const model = await service.upload(name, filePath);
      return success(res, model, HTTP_STATUS.CREATED);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.BAD_REQUEST);
    }
  }
}