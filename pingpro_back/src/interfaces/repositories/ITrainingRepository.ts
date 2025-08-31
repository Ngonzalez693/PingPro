import { ITraining } from '../models/ITraining';

export interface ITrainingRepository {
  getAll(): Promise<ITraining[]>;
  getById(id: string): Promise<ITraining | null>;
  create(training: ITraining): Promise<string>;
  update(id: string, training: Partial<ITraining>): Promise<void>;
  delete(id: string): Promise<void>;
}
