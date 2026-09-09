/**
 * Contrato de persistencia de entrenamientos. Mismo CRUD que
 * IExerciseRepository; ver ahí la explicación del patrón.
 */
import { ITraining } from '../models/ITraining';

// Interface for training repository
export interface ITrainingRepository {
  getAll(): Promise<ITraining[]>;
  getById(id: string): Promise<ITraining | null>;
  create(training: ITraining): Promise<string>;
  update(id: string, training: Partial<ITraining>): Promise<void>;
  delete(id: string): Promise<void>;

  exists(id: string): Promise<boolean>;
}
