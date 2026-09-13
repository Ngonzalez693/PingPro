/**
 * Contrato de persistencia de modelos 3D.
 *
 * Es de solo lectura: los .glb y sus documentos se suben por fuera de la API,
 * así que no hay create ni delete.
 */
import { IModel3D } from '../models/IModel3D';

export interface IModel3DRepository {
  getAll(): Promise<IModel3D[]>;   // del más nuevo al más antiguo (createdAt)
  getById(id: string): Promise<IModel3D | null>;
}

export default IModel3DRepository;
