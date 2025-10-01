import type { IUserExerciseState } from '../models/IUserExerciseState';

export interface IUserExerciseStateRepository {
  setFavorite(userId: string, exerciseId: string, isFavorite: boolean): Promise<IUserExerciseState>;
  setCompleted(userId: string, exerciseId: string, completed: boolean): Promise<IUserExerciseState>;
  getState(userId: string, exerciseId: string): Promise<IUserExerciseState | null>;
  getAllStates(userId: string): Promise<IUserExerciseState[]>;
}
