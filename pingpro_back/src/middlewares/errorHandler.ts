/**
 * Manejador de errores global de Express (4 parámetros = error middleware).
 * Registrado al final de app.ts; los controllers le pasan sus errores con
 * next(err).
 *
 * Es el único sitio que decide qué ve el usuario: un HttpError sale con su
 * status y su mensaje (los servicios los escriben para la app); cualquier otro
 * error sale como 500 genérico y el detalle solo va al log, porque puede
 * llevar SQL, nombres de restricciones o datos internos.
 */
import { Request, Response, NextFunction } from 'express';
import { HttpError } from '../utils/httpError';
import { error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';
import logger from '../utils/logger';

const INTERNAL_ERROR_MESSAGE = 'Error interno del servidor';

export default function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  // Express reconoce el middleware de errores por tener 4 parámetros.
  _next: NextFunction,
) {
  if (err instanceof HttpError) {
    return error(res, err.message, err.status);
  }
  // express.raw rechaza la foto de más de 2 MB con este tipo de error.
  if ((err as { type?: unknown } | null)?.type === 'entity.too.large') {
    return error(res, 'La foto pesa demasiado (máximo 2 MB)', HTTP_STATUS.PAYLOAD_TOO_LARGE);
  }
  logger.error(err instanceof Error ? err.stack ?? err.message : String(err));
  return error(res, INTERNAL_ERROR_MESSAGE, HTTP_STATUS.INTERNAL_ERROR);
}
