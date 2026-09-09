/**
 * Acceso a users/{uid}/trainingStates. Mismo patrón que el repositorio de
 * estados de ejercicio: el id del documento es el id del entrenamiento y las
 * escrituras van con merge.
 *
 * setProgress existe en el repositorio y en TrainingService, pero hoy ninguna
 * ruta lo expone: la app deriva el progreso contando ejercicios completados.
 */
import { firestore } from 'firebase-admin';
import type { IUserTrainingStateRepository } from '../../interfaces/repositories/IUserTrainingStateRepository';
import type { IUserTrainingState } from '../../interfaces/models/IUserTrainingState';

export default class FirebaseUserTrainingStateRepository implements IUserTrainingStateRepository {
    private col(userId: string) {
        return firestore().collection('users').doc(userId).collection('trainingStates');
    }
    private doc(userId: string, trainingId: string) {
        return this.col(userId).doc(trainingId);
    }

    async setCompleted(userId: string, trainingId: string, completed: boolean): Promise<IUserTrainingState> {
        const now = firestore.Timestamp.now();
        const ref = this.doc(userId, trainingId);
        await ref.set(
            { userId, trainingId, completedAt: completed ? now : null, updatedAt: now },
            { merge: true }
        );
        const snap = await ref.get();
        return snap.data() as IUserTrainingState;
    }

    async setProgress(userId: string, trainingId: string, progress: number): Promise<IUserTrainingState> {
        const now = firestore.Timestamp.now();
        const ref = this.doc(userId, trainingId);
        await ref.set(
            { userId, trainingId, progress, updatedAt: now },
            { merge: true }
        );
        const snap = await ref.get();
        return snap.data() as IUserTrainingState;
    }

    async getState(userId: string, trainingId: string): Promise<IUserTrainingState | null> {
        const snap = await this.doc(userId, trainingId).get();
        return snap.exists ? (snap.data() as IUserTrainingState) : null;
    }

    async getAllStates(userId: string): Promise<IUserTrainingState[]> {
        const qs = await this.col(userId).get();
        return qs.docs.map(d => d.data() as IUserTrainingState);
    }
}
