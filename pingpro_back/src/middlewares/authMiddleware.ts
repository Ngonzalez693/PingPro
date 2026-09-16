/**
 * Verifica el ID token de Firebase y deja el uid en req.user.
 *
 * Es la única fuente de identidad del backend: todo lo que escribe a nombre de
 * un usuario toma el uid de aquí, nunca de la URL o el body. Por eso un
 * usuario no puede tocar los datos de otro aunque adivine su id.
 *
 * El token lo genera la app con getIdToken() y viaja como
 * `Authorization: Bearer <token>`.
 *
 * La instancia de Auth viene de config/firebase: llamando a auth() de
 * firebase-admin aquí, si el SDK no estuviera inicializado, el catch de abajo
 * convertiría el fallo en un 401 y todas las peticiones parecerían "sin
 * sesión" sin ninguna pista de por qué.
 */
import { Request, Response, NextFunction } from 'express';
import { auth } from '../config/firebase';

export default async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }
  const [, idToken] = authHeader.split(' ');
  try {
    const decoded = await auth.verifyIdToken(idToken);
    req.user = { uid: decoded.uid };
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
