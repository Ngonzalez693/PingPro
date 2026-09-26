/**
 * Error que sí se le puede enseñar al usuario: lleva el status HTTP y un
 * mensaje pensado para la app (p. ej. 404 'Training not found').
 *
 * Los servicios lo lanzan para los casos de negocio. Cualquier otro error
 * (Postgres, Firebase, un bug) llega a errorHandler como 500 genérico y su
 * mensaje solo va al log: puede llevar SQL, nombres de restricciones o datos
 * internos.
 */
export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}
