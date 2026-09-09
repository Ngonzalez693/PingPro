/**
 * Contrato de persistencia de ejercicios (patrón Repository).
 *
 * ExerciseService depende de esta interfaz, no de la implementación de
 * Firestore. Es la frontera que permite cambiar de base de datos escribiendo
 * otra clase en repositories/implementations sin tocar la lógica de negocio.
 */
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
