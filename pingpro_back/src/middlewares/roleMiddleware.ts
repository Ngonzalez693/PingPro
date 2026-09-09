/**
 * Autorización por rol y por propiedad.
 *
 * Va SIEMPRE después de authMiddleware: ese valida el token y deja el uid en
 * req.user; estos deciden si ese uid tiene permiso para la operación.
 *
 * Los roles se leen del documento users/{uid} en Firestore, no del token. Es
 * una lectura extra por petición, pero evita tener que refrescar el token de
 * un usuario cada vez que le cambian el rol.
 */
import { Request, Response, NextFunction } from 'express';
import { UserService } from '@services/UserService';
import { error } from '@utils/apiResponse';
import { HTTP_STATUS } from '@utils/constants';

const service = new UserService();

/** true si el usuario tiene alguno de los roles pedidos. */
async function hasAnyRole(uid: string, roles: string[]): Promise<boolean> {
  try {
    const user = await service.getById(uid);
    const userRoles = user.roles ?? [];
    return roles.some((role) => userRoles.includes(role));
  } catch {
    // getById lanza 404 si el perfil no existe: sin perfil no hay rol.
    return false;
  }
}

/** Exige que el usuario autenticado tenga alguno de los roles indicados. */
export const requireRole =
  (...roles: string[]) =>
  async (req: Request, res: Response, next: NextFunction) => {
    const uid = req.user?.uid;
    if (!uid) return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);

    if (!(await hasAnyRole(uid, roles))) {
      return error(res, 'Forbidden', HTTP_STATUS.FORBIDDEN);
    }
    return next();
  };

/**
 * Permite la operación si el usuario actúa sobre su propio recurso
 * (req.params.id === su uid) o si tiene alguno de los roles indicados.
 *
 * Es lo que impide que un usuario edite o borre la cuenta de otro conociendo
 * su uid.
 */
export const requireSelfOrRole =
  (...roles: string[]) =>
  async (req: Request, res: Response, next: NextFunction) => {
    const uid = req.user?.uid;
    if (!uid) return error(res, 'Unauthorized', HTTP_STATUS.UNAUTHORIZED);

    if (uid === req.params.id) return next();

    if (!(await hasAnyRole(uid, roles))) {
      return error(res, 'Forbidden', HTTP_STATUS.FORBIDDEN);
    }
    return next();
  };
