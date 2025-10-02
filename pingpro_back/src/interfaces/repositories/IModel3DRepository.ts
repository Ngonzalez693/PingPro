import { IModel3D } from '@/interfaces/models/IModel3D';

export interface IModel3DRepository {
  createFromUrl(data: {
    name: string;
    url: string;
  }): Promise<IModel3D>;

  getAll(): Promise<IModel3D[]>;
  getById(id: string): Promise<IModel3D | null>;
  delete(id: string): Promise<void>;
}

export default IModel3DRepository;
