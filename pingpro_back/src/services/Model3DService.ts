/**
 * Servicio del catálogo de modelos 3D (solo lectura).
 *
 * Lo crea una sola vez src/container.ts, que le pasa el repositorio.
 */
import type { IModel3D } from '../interfaces/models/IModel3D';
import type { IModel3DRepository } from '../interfaces/repositories/IModel3DRepository';

export default class Model3DService {
  constructor(private readonly repo: IModel3DRepository) {}

  list(): Promise<IModel3D[]> { return this.repo.getAll(); }
  get(id: string): Promise<IModel3D | null> { return this.repo.getById(id); }
}
