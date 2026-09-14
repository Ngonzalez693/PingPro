/**
 * Acceso a users/{uid}/trainingStates. Mismo patrón que el repositorio de
 * estados de ejercicio: el id del documento es el id del entrenamiento, las
 * escrituras van con merge y las fechas se convierten a Date al leer.
 */
import { firestore } from 'firebase-admin';
import type { IUserTrainingStateRepository } from '../../interfaces/repositories/IUserTrainingStateRepository';
import type { IUserTrainingState } from '../../interfaces/models/IUserTrainingState';

function toState(data: firestore.DocumentData): IUserTrainingState {
    return {
        userId: data.userId,
        trainingId: data.trainingId,
        completedAt: data.completedAt ? (data.completedAt as firestore.Timestamp).toDate() : null,
        updatedAt: (data.updatedAt as firestore.Timestamp).toDate(),
    };
}

export default class FirebaseUserTrainingStateRepository implements IUserTrainingStateRepository {
    private col(userId: string) {
        return firestore().collection('users').doc(userId).collection('trainingStates');
    }
    private doc(userId: string, trainingId: string) {
        return this.col(userId).doc(trainingId);
    }

    async setCompleted(userId: string, trainingId: string, completed: boolean): Promise<IUserTrainingState> {
        const now = new Date();
        const ref = this.doc(userId, trainingId);
        await ref.set(
            { userId, trainingId, completedAt: completed ? now : null, updatedAt: now },
            { merge: true }
        );
        const snap = await ref.get();
        return toState(snap.data()!);
    }

    async getState(userId: string, trainingId: string): Promise<IUserTrainingState | null> {
        const snap = await this.doc(userId, trainingId).get();
        return snap.exists ? toState(snap.data()!) : null;
    }

    async getAllStates(userId: string): Promise<IUserTrainingState[]> {
        const qs = await this.col(userId).get();
        return qs.docs.map(d => toState(d.data()));
    }
}
