/**
 * Límites de peticiones por IP.
 *
 * El registro crea las cuentas con el Admin SDK, que se salta la protección por
 * IP que Firebase Auth aplica a los registros desde el cliente: sin este límite,
 * el endpoint crearía cuentas sin tope.
 *
 * La IP sale de req.ip, que solo es la del cliente real si `trust proxy` está
 * bien ajustado en app.ts (ver TRUST_PROXY_HOPS). El contador vive en memoria:
 * se reinicia si Hostinger reinicia la app y no se comparte entre procesos.
 */
import rateLimit, { RateLimitRequestHandler } from 'express-rate-limit';
import { error } from '../utils/apiResponse';
import { HTTP_STATUS } from '../utils/constants';

// 20 cada 15 min: holgado para las IPs compartidas de los operadores móviles
// (CGNAT) y para un club que se registra desde el mismo wifi, pero frena la
// creación masiva de cuentas.
export const signupLimiter: RateLimitRequestHandler = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: (_req, res) => {
    error(
      res,
      'Demasiados registros desde esta red. Intenta de nuevo en unos minutos.',
      HTTP_STATUS.TOO_MANY_REQUESTS,
    );
  },
});
