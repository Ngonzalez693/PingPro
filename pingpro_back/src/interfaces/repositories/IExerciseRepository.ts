import { IExercise } from '../models/IExercise';

// Interface for exercise repository
export interface IExerciseRepository {
  getAll(): Promise<IExercise[]>;
  getById(id: string): Promise<IExercise | null>;
  create(exercise: IExercise): Promise<string>;
  update(id: string, exercise: Partial<IExercise>): Promise<void>;
  delete(id: string): Promise<void>;

  exists(id: string): Promise<boolean>;
}
