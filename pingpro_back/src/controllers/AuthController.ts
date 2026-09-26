/**
 * Controlador de autenticación.
 *
 * signUp es el único punto donde se crea una cuenta: hace dos escrituras
 * (Firebase Auth + documento en Firestore) usando el mismo uid como clave, para
 * que el perfil y la credencial queden siempre enlazados.
 */
import { Request, Response, NextFunction } from 'express';
import { services } from '../container';
import { success, error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';
import { HttpError } from '../utils/httpError';

const authService = services.auth;
const userService = services.users;

// firebase-admin marca sus errores de cuenta con códigos 'auth/...'.
function isFirebaseAuthError(err: unknown): err is { code: string; message: string } {
  const code = (err as { code?: unknown } | null)?.code;
  return typeof code === 'string' && code.startsWith('auth/');
}

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
      // Los errores de cuenta de Firebase ("email ya en uso", contraseña
      // débil...) son para el usuario; cualquier otro (p. ej. Postgres al
      // crear el perfil) va a errorHandler como 500 sin detalles.
      return next(isFirebaseAuthError(err) ? new HttpError(HTTP_STATUS.BAD_REQUEST, err.message) : err);
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
