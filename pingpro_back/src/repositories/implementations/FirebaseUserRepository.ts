/**
 * Acceso a la colección 'users' de Firestore.
 *
 * createWithUID es el método que se usa en el registro: fija el id del
 * documento al uid de Firebase Auth. create() (id automático) queda como parte
 * del contrato IUserRepository pero no debería usarse para usuarios reales.
 *
 * Firestore devuelve las fechas como Timestamp; toUser las convierte a Date al
 * leer para que la API las envíe como texto ISO.
 */
import { DocumentData, DocumentSnapshot, Timestamp } from 'firebase-admin/firestore';
import { IUser } from '../../interfaces/models/IUser';
import { IUserRepository } from '../../interfaces/repositories/IUserRepository';
import { database } from '../../config/database';

function toDate(value: unknown): Date | undefined {
  return value instanceof Timestamp ? value.toDate() : undefined;
}

function toUser(doc: DocumentSnapshot): IUser {
  const data: DocumentData = doc.data() ?? {};
  return {
    id: doc.id,
    ...(data as IUser),
    createdAt: toDate(data.createdAt),
    updatedAt: toDate(data.updatedAt),
  };
}

export class FirebaseUserRepository implements IUserRepository {
  private collection = database.firestore.collection('users');

  async getAll(): Promise<IUser[]> {
    const snap = await this.collection.get();
    return snap.docs.map(doc => ({ id: doc.id, ...(doc.data() as IUser) }));
  }

  async getById(id: string): Promise<IUser | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? toUser(doc) : null;
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
