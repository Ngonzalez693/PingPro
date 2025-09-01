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
