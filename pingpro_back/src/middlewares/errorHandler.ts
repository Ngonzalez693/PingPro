/**
 * Manejador de errores global de Express (4 parámetros = error middleware).
 * Registrado al final de app.ts.
 *
 * Hoy es inalcanzable: todos los controllers capturan sus propias excepciones y
 * responden con error(), así que ninguno llama a next(err). Queda como red de
 * seguridad si en algún momento se delega el manejo de errores aquí.
 */
import { Request, Response, NextFunction } from 'express';

interface HttpError extends Error {
  status?: number;
}

// Error handler helper
export default function errorHandler(
  err: HttpError,
  req: Request,
  res: Response,
  next: NextFunction
) {
  console.error(err.stack);
  const status = err.status || 500;
  res.status(status).json({ success: false, message: err.message });
}
