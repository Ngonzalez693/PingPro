/**
 * Acceso a la colección 'model3d' (nombre de animación → URL del .glb).
 *
 * Es de solo lectura: los .glb y sus documentos se suben por fuera de la API.
 *
 * toModel mapea campo por campo en vez de hacer spread: Firestore devuelve
 * Timestamp y la interfaz espera Date, así que hay que convertir con toDate().
 */
import { firestore } from 'firebase-admin';
import type { IModel3D } from '../../interfaces/models/IModel3D';
import type { IModel3DRepository } from '../../interfaces/repositories/IModel3DRepository';

const col = () => firestore().collection('model3d');

function toModel(doc: firestore.DocumentSnapshot): IModel3D {
  const data = doc.data() ?? {};
  return {
    id: doc.id,
    name: data.name,
    url: data.url,
    // Si falta la fecha (o no es un Timestamp) se rellena con la actual, como
    // hasta ahora.
    createdAt: (data.createdAt as firestore.Timestamp | undefined)?.toDate?.() ?? new Date(),
    updatedAt: (data.updatedAt as firestore.Timestamp | undefined)?.toDate?.() ?? new Date(),
  };
}

export default class FirebaseModel3DRepository implements IModel3DRepository {
  async getAll(): Promise<IModel3D[]> {
    const snap = await col().orderBy('createdAt', 'desc').get();
    return snap.docs.map((doc) => toModel(doc));
  }

  async getById(id: string): Promise<IModel3D | null> {
    const doc = await col().doc(id).get();
    return doc.exists ? toModel(doc) : null;
  }
}
