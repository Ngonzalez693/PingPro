import { IModel3D } from '@/interfaces/models/IModel3D';

export interface IModel3DRepository {
  getAll(): Promise<IModel3D[]>;
  getById(id: string): Promise<IModel3D | null>;
  create(model: IModel3D): Promise<IModel3D>;
}