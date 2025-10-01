import { IModel3DRepository } from '@/interfaces/repositories/IModel3DRepository';
import { IModel3D } from '@/interfaces/models/IModel3D';
import { db } from '@/config/firebase';
import { Model3D } from '@/models/Model3D';

const COLLECTION = 'models3d';

export default class FirebaseModel3DRepository implements IModel3DRepository {
  async getAll(): Promise<IModel3D[]> {
    const snaps = await db.collection(COLLECTION).get();
    return snaps.docs.map(doc => new Model3D({ id: doc.id, ...doc.data() } as IModel3D));
  }

  async getById(id: string): Promise<IModel3D | null> {
    const doc = await db.collection(COLLECTION).doc(id).get();
    if (!doc.exists) return null;
    return new Model3D({ id: doc.id, ...doc.data() } as IModel3D);
  }

  async create(model: IModel3D): Promise<IModel3D> {
    const now = new Date();
    const data = { 
      ...model, 
      createdAt: now, 
      updatedAt: now 
    };
    const ref = await db.collection(COLLECTION).add(data);
    return new Model3D({ id: ref.id, ...data });
  }
}