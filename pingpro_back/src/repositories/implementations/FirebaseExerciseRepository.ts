import { IExercise } from '@interfaces/models/IExercise';
import { IExerciseRepository } from '@interfaces/repositories/IExerciseRepository';
import { database } from '@config/database';

export class FirebaseExerciseRepository implements IExerciseRepository {
  private collection = database.firestore.collection('exercises');  // Database collection

  // Get all exercises from database
  async getAll(): Promise<IExercise[]> {
    const snap = await this.collection.get();
    return snap.docs.map(doc => ({ id: doc.id, ...doc.data() as IExercise }));
  }

  // Get exercises by id from database
  async getById(id: string): Promise<IExercise | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? ({ id: doc.id, ...doc.data() as IExercise }) : null;
  }

  // Create exercises for database
  async create(exercise: IExercise): Promise<string> {
    const ref = await this.collection.add(exercise);
    return ref.id;
  }

  // Update exercises from database
  async update(id: string, exercise: Partial<IExercise>): Promise<void> {
    await this.collection.doc(id).update(exercise);
  }

  // Delete exercises from database
  async delete(id: string): Promise<void> {
    await this.collection.doc(id).delete();
  }
}
