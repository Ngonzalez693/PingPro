/**
 * Contrato del estado por usuario sobre entrenamientos. Equivalente a
 * IUserExerciseStateRepository, sin favorito: solo se marca como completado.
 */
import type { IUserTrainingState } from '../models/IUserTrainingState';

export interface IUserTrainingStateRepository {
  // session: 1..3, o null si no se indica ("sin sesión"). Solo cuenta al completar.
  setCompleted(userId: string, trainingId: string, completed: boolean, session?: number | null): Promise<IUserTrainingState>;
  getState(userId: string, trainingId: string): Promise<IUserTrainingState | null>;
  getAllStates(userId: string): Promise<IUserTrainingState[]>;
}
