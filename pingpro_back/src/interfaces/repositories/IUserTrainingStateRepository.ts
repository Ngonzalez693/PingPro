/**
 * Contrato del estado por usuario sobre entrenamientos. Equivalente a
 * IUserExerciseStateRepository, sin favorito: solo se marca como completado.
 */
import type { IUserTrainingState } from '../models/IUserTrainingState';

export interface IUserTrainingStateRepository {
  setCompleted(userId: string, trainingId: string, completed: boolean): Promise<IUserTrainingState>;
  getState(userId: string, trainingId: string): Promise<IUserTrainingState | null>;
  getAllStates(userId: string): Promise<IUserTrainingState[]>;
}
