/**
 * Acceso a users/{uid}/exerciseStates: el progreso privado de cada usuario
 * sobre el catálogo compartido de ejercicios.
 *
 * El id del documento de estado ES el id del ejercicio. Eso hace que la lectura
 * sea directa (sin query) y que no puedan existir dos estados para el mismo par
 * usuario–ejercicio.
 *
 * Todas las escrituras usan `set(..., { merge: true })` para poder actualizar
 * favorito y completado por separado sin borrar el otro campo.
 */
import { firestore } from 'firebase-admin';
import type { IUserExerciseStateRepository } from '../../interfaces/repositories/IUserExerciseStateRepository';
import type { IUserExerciseState } from '../../interfaces/models/IUserExerciseState';

export default class FirebaseUserExerciseStateRepository implements IUserExerciseStateRepository {
  private col(userId: string) {
    return firestore().collection('users').doc(userId).collection('exerciseStates');
  }

  private doc(userId: string, exerciseId: string) {
    return this.col(userId).doc(exerciseId);
  }

  async setFavorite(userId: string, exerciseId: string, isFavorite: boolean): Promise<IUserExerciseState> {
    const now = firestore.Timestamp.now();
    const ref = this.doc(userId, exerciseId);
    await ref.set({ userId, exerciseId, isFavorite, updatedAt: now }, { merge: true });
    const snap = await ref.get();
    return snap.data() as IUserExerciseState;
  }

  async setCompleted(userId: string, exerciseId: string, completed: boolean): Promise<IUserExerciseState> {
    const now = firestore.Timestamp.now();
    const ref = this.doc(userId, exerciseId);
    // No se guarda un booleano: completedAt guarda CUÁNDO se completó (o null).
    // Las estadísticas de la app se construyen sobre esas fechas.
    await ref.set(
      { userId, exerciseId, completedAt: completed ? now : null, updatedAt: now },
      { merge: true }
    );
    const snap = await ref.get();
    return snap.data() as IUserExerciseState;
  }

  async getState(userId: string, exerciseId: string): Promise<IUserExerciseState | null> {
    const snap = await this.doc(userId, exerciseId).get();
    return snap.exists ? (snap.data() as IUserExerciseState) : null;
  }

  async getAllStates(userId: string): Promise<IUserExerciseState[]> {
    const qs = await this.col(userId).get();
    return qs.docs.map(d => d.data() as IUserExerciseState);
  }
}
