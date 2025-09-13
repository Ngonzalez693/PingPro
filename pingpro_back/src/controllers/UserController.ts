import { Request, Response, NextFunction } from 'express';
import { UserService } from '@services/UserService';
import { success, error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';
import { AuthService } from '@/services/AuthService';

const service = new UserService();

export default class UserController {
  static async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const users = await service.getAll();
      return success(res, users, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await service.getById(req.params.id);
      return success(res, user, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    return error(res, "Use AuthController for user creation", HTTP_STATUS.BAD_REQUEST);
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      await service.update(req.params.id, req.body);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await service.delete(req.params.id);
      return success(res, null, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.INTERNAL_ERROR);
    }
  }

  static async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const authHeader = req.headers.authorization || "";
      if (!authHeader) throw Object.assign(new Error("No token provided"), { status: 401 });
      const [, idToken] = authHeader.split(' ');
      const authService = new AuthService();
      const uid = await authService.verifyIdToken(idToken);

      const user = await service.getById(uid);
      if (!user) throw Object.assign(new Error("User not found"), { status: 404 });

      return success(res, user, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

}