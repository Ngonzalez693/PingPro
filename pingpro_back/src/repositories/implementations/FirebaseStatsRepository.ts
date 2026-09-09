/**
 * Acceso a la subcolección users/{uid}/stats.
 *
 * A diferencia de los repositorios de catálogo, aquí `collection` es una
 * función de userId: cada usuario tiene su propia subcolección, así que la
 * ruta no se puede resolver hasta saber de quién se trata.
 */
import { IStatsRepository } from '@interfaces/repositories/IStatsRepository';
import { IUserStat } from '@interfaces/models/IUserStat';
import { database } from '@config/database';

export class FirebaseStatsRepository implements IStatsRepository {
  private collection = (userId: string) =>
    database.firestore.collection('users').doc(userId).collection('stats');

  async getAllByUser(userId: string): Promise<IUserStat[]> {
    const snap = await this.collection(userId).orderBy('timestamp', 'asc').get();
    return snap.docs.map(doc => ({ id: doc.id, ...doc.data() as IUserStat }));
  }

  async getById(userId: string, id: string): Promise<IUserStat | null> {
    const doc = await this.collection(userId).doc(id).get();
    return doc.exists ? ({ id: doc.id, ...doc.data() as IUserStat }) : null;
  }

  async create(stat: IUserStat): Promise<string> {
    const ref = await this.collection(stat.userId).add({ ...stat });
    return ref.id;
  }

  async update(userId: string, id: string, stat: Partial<IUserStat>): Promise<void> {
    await this.collection(userId).doc(id).update(stat);
  }

  async delete(userId: string, id: string): Promise<void> {
    await this.collection(userId).doc(id).delete();
  }
}
