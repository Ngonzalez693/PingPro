/**
 * Acceso a la colección 'model3d' (nombre de animación → URL del .glb).
 *
 * A diferencia de los otros repositorios, aquí se mapea campo por campo en vez
 * de hacer spread: Firestore devuelve Timestamp y la interfaz espera Date, así
 * que hay que convertir con toDate().
 */
import { firestore } from 'firebase-admin';
import { IModel3D } from '../../interfaces/models/IModel3D';

const col = () => firestore().collection('model3d');

export default class FirebaseModel3DRepository {
  async getAll(): Promise<IModel3D[]> {
    const snap = await col().orderBy('createdAt', 'desc').get();
    return snap.docs.map((d) => {
      const x = d.data() as any;
      return {
        id: d.id,
        name: x.name,
        url: x.url,
        createdAt: x.createdAt?.toDate?.() ?? new Date(),
        updatedAt: x.updatedAt?.toDate?.() ?? new Date(),
      } as IModel3D;
    });
  }

  async getById(id: string): Promise<IModel3D | null> {
    const doc = await col().doc(id).get();
    if (!doc.exists) return null;
    const x = doc.data() as any;
    return {
      id: doc.id,
      name: x.name,
      url: x.url,
      createdAt: x.createdAt?.toDate?.() ?? new Date(),
      updatedAt: x.updatedAt?.toDate?.() ?? new Date(),
    } as IModel3D;
  }
}
