/**
 * Acceso a la colección 'users' de Firestore.
 *
 * El id del documento es siempre el uid de Firebase Auth: createWithUID lo
 * fija en el registro.
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

  async getById(id: string): Promise<IUser | null> {
    const doc = await this.collection.doc(id).get();
    return doc.exists ? toUser(doc) : null;
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
