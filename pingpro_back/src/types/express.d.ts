/**
 * Amplía el tipo Request de Express con `user`.
 *
 * Es lo que permite escribir `req.user.uid` con tipado después de que
 * authMiddleware lo inyecta. Opcional (`?`) porque en las rutas públicas no
 * existe.
 */
import 'express-serve-static-core';

declare module 'express-serve-static-core' {
  interface Request {
    user?: { uid: string };
  }
}