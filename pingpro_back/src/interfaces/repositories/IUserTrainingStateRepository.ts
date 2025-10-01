import type { IUserTrainingState } from '@/interfaces/models/IUserTrainingState';

export interface IUserTrainingStateRepository {
  setCompleted(userId: string, trainingId: string, completed: boolean): Promise<IUserTrainingState>;
  setProgress(userId: string, trainingId: string, progress: number): Promise<IUserTrainingState>;
  getState(userId: string, trainingId: string): Promise<IUserTrainingState | null>;
  getAllStates(userId: string): Promise<IUserTrainingState[]>;
}
