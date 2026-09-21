/**
 * Contrato de persistencia de entrenamientos. Mismo CRUD que
 * IExerciseRepository; ver ahí la explicación del patrón.
 */
import { ITraining } from '../models/ITraining';

// Interface for training repository
export interface ITrainingRepository {
  getAll(viewerId: string | null): Promise<ITraining[]>;
  getById(id: string, viewerId: string | null): Promise<ITraining | null>;
  create(training: ITraining): Promise<string>;
  update(id: string, training: Partial<ITraining>): Promise<void>;
  delete(id: string): Promise<void>;

  exists(id: string, viewerId: string | null): Promise<boolean>;
}
