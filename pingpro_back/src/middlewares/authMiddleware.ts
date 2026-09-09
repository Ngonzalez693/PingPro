/**
 * Verifica el ID token de Firebase y deja el uid en req.user.
 *
 * Es la única fuente de identidad del backend: todo lo que escribe en
 * users/{uid}/... toma el uid de aquí, nunca de la URL o el body. Por eso un
 * usuario no puede tocar los datos de otro aunque adivine su id.
 *
 * El token lo genera la app con getIdToken() y viaja como
 * `Authorization: Bearer <token>`.
 */
import { auth } from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';

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
    const decoded = await auth().verifyIdToken(idToken);
    req.user = { uid: decoded.uid };
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
