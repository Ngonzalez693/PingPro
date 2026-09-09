/**
 * Servicio del catálogo de modelos 3D (solo lectura).
 *
 * Singleton (`instance`): el catálogo es el mismo para toda la app y no guarda
 * estado por petición, así que no tiene sentido instanciarlo por request.
 */
import FirebaseModel3DRepository from '../repositories/implementations/FirebaseModel3DRepository';
import { IModel3D } from '../interfaces/models/IModel3D';

export default class Model3DService {
  private static _i: Model3DService;
  private repo = new FirebaseModel3DRepository();
  static get instance() { return this._i ??= new Model3DService(); }

  list(): Promise<IModel3D[]> { return this.repo.getAll(); }
  get(id: string): Promise<IModel3D | null> { return this.repo.getById(id); }
}
