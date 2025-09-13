import { IUser } from '@interfaces/models/IUser';
import { IUserRepository } from '@interfaces/repositories/IUserRepository';
import { database } from '@config/database';

export class FirebaseUserRepository implements IUserRepository {
  private collection = database.firestore.collection('users');

  async getAll(): Promise<IUser[]> {
    const snap = await this.collection.get();
    return snap.docs.map(doc => ({ id: doc.id, ...(doc.data() as IUser) }));
  }

  async getById(id: string): Promise<IUser | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? { id: doc.id, ...(doc.data() as IUser) } : null;
  }

  async getByEmail(email: string): Promise<IUser | null> {
    const snap = await this.collection.where('email', '==', email).limit(1).get();
    if (snap.empty) return null;
    const doc = snap.docs[0];
    return { id: doc.id, ...(doc.data() as IUser) };
  }

  async create(user: IUser): Promise<string> {
    const ref = await this.collection.add(user);
    return ref.id;
  }

  async createWithUID(uid: string, user: IUser): Promise<void> {
    await this.collection.doc(uid).set(user);
  }

  async update(id: string, user: Partial<IUser>): Promise<void> {
    await this.collection.doc(id).update({ ...user, updatedAt: new Date() });
  }

  async delete(id: string): Promise<void> {
    await this.collection.doc(id).delete();
  }
}
