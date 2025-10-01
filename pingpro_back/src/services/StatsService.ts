import { IUserStat } from '@interfaces/models/IUserStat';
import { FirebaseStatsRepository } from '@repositories/implementations/FirebaseStatsRepository';

export class StatsService {
  private repo = new FirebaseStatsRepository();

  async getAllForUser(userId: string): Promise<IUserStat[]> {
    return this.repo.getAllByUser(userId);
  }

  async getById(userId: string, id: string): Promise<IUserStat> {
    const stat = await this.repo.getById(userId, id);
    if (!stat) throw Object.assign(new Error('Stat not found'), { status: 404 });
    return stat;
  }

  async createOrUpdate(userId: string, data: IUserStat): Promise<IUserStat> {
    data.userId = userId;
    data.timestamp = new Date();
    if (data.id) {
      await this.repo.update(userId, data.id, data);
      return this.getById(userId, data.id!);
    } else {
      const id = await this.repo.create(data);
      return this.getById(userId, id);
    }
  }
}
