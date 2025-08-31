import { ITraining } from '@interfaces/models/ITraining';
import { ITrainingRepository } from '@interfaces/repositories/ITrainingRepository';
import { database } from '@config/database';

export class FirebaseTrainingRepository implements ITrainingRepository {
  private collection = database.firestore.collection('trainings');

  async getAll(): Promise<ITraining[]> {
    const snap = await this.collection.get();
    return snap.docs.map(doc => ({ id: doc.id, ...doc.data() as ITraining }));
  }

  async getById(id: string): Promise<ITraining | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? ({ id: doc.id, ...doc.data() as ITraining }) : null;
  }

  async create(training: ITraining): Promise<string> {
    const ref = await this.collection.add(training);
    return ref.id;
  }

  async update(id: string, training: Partial<ITraining>): Promise<void> {
    await this.collection.doc(id).update({ ...training, updatedAt: new Date() });
  }

  async delete(id: string): Promise<void> {
    await this.collection.doc(id).delete();
  }
}
