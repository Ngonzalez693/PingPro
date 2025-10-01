import { IUserStat } from '@interfaces/models/IUserStat';

export interface IStatsRepository {
  getAllByUser(userId: string): Promise<IUserStat[]>;
  getById(userId: string, id: string): Promise<IUserStat | null>;
  create(stat: IUserStat): Promise<string>;
  update(userId: string, id: string, stat: Partial<IUserStat>): Promise<void>;
  delete(userId: string, id: string): Promise<void>;
}
