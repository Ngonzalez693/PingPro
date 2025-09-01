import { Request, Response, NextFunction } from 'express';
import { AuthService } from '@services/AuthService';
import { success, error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';

const authService = new AuthService();

export default class AuthController {
  static async signUp(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password, displayName } = req.body;
      const userRecord = await authService.signUp(email, password, displayName);
      return success(res, { uid: userRecord.uid, email: userRecord.email }, HTTP_STATUS.CREATED);
    } catch (err) {
      return error(res, (err as Error).message, HTTP_STATUS.BAD_REQUEST);
    }
  }

  static async verifyToken(req: Request, res: Response, next: NextFunction) {
    try {
      const authHeader = req.headers.authorization || '';
      const [, idToken] = authHeader.split(' ');
      const uid = await authService.verifyIdToken(idToken);
      return success(res, { uid }, HTTP_STATUS.OK);
    } catch {
      return error(res, 'Token inválido o expirado', HTTP_STATUS.UNAUTHORIZED);
    }
  }
}
