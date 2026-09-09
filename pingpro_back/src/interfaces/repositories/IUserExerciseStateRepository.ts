/**
 * Contrato del estado por usuario sobre ejercicios.
 *
 * No es un CRUD genérico: expone acciones del dominio (setFavorite,
 * setCompleted) en vez de update(), porque cada una es un upsert parcial sobre
 * el mismo documento y no deben pisarse entre sí.
 */
import type { IUserExerciseState } from '../models/IUserExerciseState';

export interface IUserExerciseStateRepository {
  setFavorite(userId: string, exerciseId: string, isFavorite: boolean): Promise<IUserExerciseState>;
  setCompleted(userId: string, exerciseId: string, completed: boolean): Promise<IUserExerciseState>;
  getState(userId: string, exerciseId: string): Promise<IUserExerciseState | null>;
  getAllStates(userId: string): Promise<IUserExerciseState[]>;
}
