/**
 * Reglas de negocio de entrenamientos. Mismo esquema que ExerciseService:
 * catálogo compartido ('trainings') + estado privado
 * (users/{uid}/trainingStates).
 *
 * getAllWithUserState es la pieza clave: Firestore no permite join, así que el
 * cruce entre catálogo y progreso se hace aquí en memoria.
 */
import { ITraining } from '@interfaces/models/ITraining';
import { FirebaseTrainingRepository } from '@repositories/implementations/FirebaseTrainingRepository';
import FirebaseUserTrainingStateRepository from '@repositories/implementations/FirebaseUserTrainingStateRepository';
import type { IUserTrainingState } from '@interfaces/models/IUserTrainingState';

export class TrainingService {
  private trainingRepo = new FirebaseTrainingRepository();
  private userTrainingStateRepo = new FirebaseUserTrainingStateRepository();

  // Get all trainings from repository
  async getAll(): Promise<ITraining[]> {
    return this.trainingRepo.getAll();
  }

  // Get training by id from repository
  async getById(id: string): Promise<ITraining> {
    const training = await this.trainingRepo.getById(id);
    if (!training) {
      throw Object.assign(new Error('Training not found'), { status: 404 });
    }
    return training;
  }

  // Create training from repository
  async create(data: ITraining): Promise<string> {
    const trainingData = { ...data, createdAt: new Date(), updatedAt: new Date() };
    return this.trainingRepo.create(trainingData);
  }

  // Update training from repository
  async update(id: string, data: Partial<ITraining>): Promise<void> {
    await this.getById(id); // validate existance
    await this.trainingRepo.update(id, data);
  }

  // Delete training from repository
  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.trainingRepo.delete(id);
  }

  //  Completar entrenamiento por usuario 
  async setCompletedForUser(userId: string, trainingId: string, completed: boolean): Promise<IUserTrainingState> {
    const exists = await this.trainingRepo.exists(trainingId);
    if (!exists) {
      const err: any = new Error('Training not found');
      err.status = 404;
      throw err;
    }
    return this.userTrainingStateRepo.setCompleted(userId, trainingId, completed);
  }

  // Obtener todos los estados del usuario 
  async getUserTrainingStates(userId: string): Promise<IUserTrainingState[]> {
    return this.userTrainingStateRepo.getAllStates(userId);
  }

  // Progress
  async setProgressForUser(userId: string, trainingId: string, progress: number): Promise<IUserTrainingState> {
    const exists = await this.trainingRepo.exists(trainingId);
    if (!exists) {
      const err: any = new Error('Training not found');
      err.status = 404;
      throw err;
    }
    return this.userTrainingStateRepo.setProgress(userId, trainingId, progress);
  }

  async getAllWithUserState(userId: string): Promise<Array<ITraining & {
    isCompleted: boolean;
    completedAt?: string | null; // ISO
  }>> {
    // Las dos lecturas son independientes → en paralelo, no en secuencia.
    const [trainings, states] = await Promise.all([
      this.getAll(),
      this.userTrainingStateRepo.getAllStates(userId),
    ]);

    // Índice por id para cruzar en O(n) en vez de recorrer states por cada training.
    const byId = new Map(states.map(s => [s.trainingId, s]));

    return trainings.map(t => {
      // Ajusta si tu modelo usa otra propiedad de id
      const tid = (t as any).id || (t as any).trainingId || t.id;
      const st = byId.get(tid);

      const completedAt = st?.completedAt ? st.completedAt.toDate().toISOString() : null;
      return {
        ...t,
        isCompleted: !!st?.completedAt,
        completedAt,
      };
    });
  }
}
