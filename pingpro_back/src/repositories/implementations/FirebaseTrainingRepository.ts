import { ITraining } from '@interfaces/models/ITraining';
import { ITrainingRepository } from '@interfaces/repositories/ITrainingRepository';
import { database } from '@config/database';

export class FirebaseTrainingRepository implements ITrainingRepository {
  private collection = database.firestore.collection('trainings');    // Database collection

  // Get all trainings from database
  async getAll(): Promise<ITraining[]> {
    const snap = await this.collection.get();
    return snap.docs.map(doc => ({ id: doc.id, ...doc.data() as ITraining }));
  }

  // Get trainings by id from database
  async getById(id: string): Promise<ITraining | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? ({ id: doc.id, ...doc.data() as ITraining }) : null;
  }

  // Create trainings for database
  async create(training: ITraining): Promise<string> {
    const ref = await this.collection.add(training);
    return ref.id;
  }

  // Update trainings from database
  async update(id: string, training: Partial<ITraining>): Promise<void> {
    await this.collection.doc(id).update({ ...training, updatedAt: new Date() });
  }

  // Delete trainings from database
  async delete(id: string): Promise<void> {
    await this.collection.doc(id).delete();
  }
}
