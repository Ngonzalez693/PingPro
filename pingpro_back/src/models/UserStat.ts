/**
 * Clase de dominio de una estadística.
 * SIN USO — ver la nota en models/Exercise.ts.
 */
import { IUserStat } from '@interfaces/models/IUserStat';

export class UserStat implements IUserStat {
  id?: string;
  userId: string;
  exerciseCount: number;
  trainingCount: number;
  timestamp: Date;

  constructor(data: IUserStat) {
    this.id = data.id;
    this.userId = data.userId;
    this.exerciseCount = data.exerciseCount;
    this.trainingCount = data.trainingCount;
    this.timestamp = data.timestamp;
  }
}
