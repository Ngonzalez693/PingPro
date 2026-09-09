/**
 * Controlador de usuarios (perfil en Firestore, no credenciales).
 *
 * create() está deshabilitado a propósito: la creación pasa siempre por
 * AuthController.signUp, que es el único lugar que garantiza que el uid de
 * Firebase Auth y el id del documento coincidan.
 */
import { Request, Response, NextFunction } from 'express';
import { UserService } from '@services/UserService';
import { success, error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';

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

  // El uid lo pone authMiddleware, que ya validó el token. getById lanza un
  // error con status 404 si el perfil no existe.
  static async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const uid = req.user?.uid;
      if (!uid) return error(res, "Unauthorized", HTTP_STATUS.UNAUTHORIZED);

      const user = await service.getById(uid);
      return success(res, user, HTTP_STATUS.OK);
    } catch (err) {
      return error(res, (err as Error).message, (err as any).status || HTTP_STATUS.INTERNAL_ERROR);
    }
  }

}