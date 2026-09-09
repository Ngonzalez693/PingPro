/**
 * Controlador de autenticación.
 *
 * signUp es el único punto donde se crea una cuenta: hace dos escrituras
 * (Firebase Auth + documento en Firestore) usando el mismo uid como clave, para
 * que el perfil y la credencial queden siempre enlazados.
 */
import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/AuthService';
import { UserService } from '../services/UserService';
import { success, error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';

const authService = new AuthService();
const userService = new UserService();

export default class AuthController {
  static async signUp(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password, displayName } = req.body;
      const userRecord = await authService.signUp(email, password, displayName);

      // El uid que devuelve Firebase Auth se reutiliza como id del documento en
      // Firestore. Sin esto no habría forma de relacionar credencial y perfil.
      // Crear perfil usuario en Firestore con UID
      await userService.create({
        id: userRecord.uid,
        email,
        displayName: displayName ?? '',
        roles: ['user'],
        createdAt: new Date(),
        updatedAt: new Date(),
      });

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
