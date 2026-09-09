/**
 * Formato único de respuesta de la API: { success, data } o { success, message }.
 *
 * Que todos los controllers pasen por aquí es lo que permite al frontend leer
 * siempre `data.data`. La excepción es Model3DController, que responde JSON
 * crudo — de ahí que los servicios en Dart tengan que aceptar ambas formas.
 */
import { Response } from 'express';

// Success response
export const success = (res: Response, data: any, status = 200) =>
  res.status(status).json({ success: true, data });

// Error response
export const error = (res: Response, message: string, status = 500) =>
  res.status(status).json({ success: false, message });
