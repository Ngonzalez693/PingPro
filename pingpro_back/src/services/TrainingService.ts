/**
 * Reglas de negocio de entrenamientos. Mismo esquema que ExerciseService:
 * catálogo compartido ('trainings') + estado privado
 * (users/{uid}/trainingStates).
 *
 * getAllWithUserState es la pieza clave: Firestore no permite join, así que el
 * cruce entre catálogo y progreso se hace aquí en memoria.
 *
 * También recibe el repositorio de ejercicios, solo para comprobar que los
 * exerciseIds existen antes de guardar un entrenamiento.
 */
import { ITraining } from '../interfaces/models/ITraining';
import type { IExerciseRepository } from '../interfaces/repositories/IExerciseRepository';
import type { IUserTrainingState } from '../interfaces/models/IUserTrainingState';
import type { ITrainingRepository } from '../interfaces/repositories/ITrainingRepository';
import type { IUserTrainingStateRepository } from '../interfaces/repositories/IUserTrainingStateRepository';
import { HttpError } from '../utils/httpError';

export class TrainingService {
  // Los recibe de src/container.ts: el servicio solo conoce las interfaces.
  constructor(
    private readonly trainingRepo: ITrainingRepository,
    private readonly userTrainingStateRepo: IUserTrainingStateRepository,
    private readonly exerciseRepo: IExerciseRepository,
  ) {}

  // Get all trainings from repository
  //
  // `viewerId` es quién pregunta: catálogo + sus entrenamientos privados. Uno
  // privado de otro usuario es un 404, igual que en ExerciseService.
  async getAll(viewerId: string): Promise<ITraining[]> {
    return this.trainingRepo.getAll(viewerId);
  }

  // Get training by id from repository
  async getById(id: string, viewerId: string): Promise<ITraining> {
    return this.requireVisible(id, viewerId);
  }

  // ESCRITURAS
  //
  // `ownerId` null es el catálogo (rutas de admin) y un uid son los
  // entrenamientos privados de ese usuario (rutas /me).
  //
  // Es también el viewer con el que se validan los exerciseIds, y de ahí sale
  // la regla de mezcla: el entrenamiento privado de un usuario puede usar
  // ejercicios del catálogo y los suyos, pero no los de otro; y uno del
  // catálogo solo puede usar ejercicios del catálogo.

  // Create training from repository
  async create(data: ITraining, ownerId: string | null): Promise<string> {
    await this.assertExercisesVisible(data.exerciseIds, ownerId);
    return this.trainingRepo.create(data, ownerId);
  }

  // Update training from repository
  async update(id: string, data: Partial<ITraining>, ownerId: string | null): Promise<void> {
    await this.requireOwned(id, ownerId); // validate existance
    if (data.exerciseIds) {
      await this.assertExercisesVisible(data.exerciseIds, ownerId);
    }
    await this.trainingRepo.update(id, data, ownerId);
  }

  // Sin esta comprobación, un entrenamiento podría apuntar a ejercicios que no
  // existen: Firestore lo acepta, pero la clave foránea de Postgres lo
  // rechazaría con un 500.
  //
  // Mirar con `viewerId` hace además que un entrenamiento solo pueda referirse
  // a ejercicios que su dueño ve. Con null (catálogo) eso impide que un
  // entrenamiento público apunte al ejercicio privado de alguien, que daría
  // 404 para todos los demás.
  private async assertExercisesVisible(exerciseIds: string[], viewerId: string | null): Promise<void> {
    const uniqueIds = [...new Set(exerciseIds)];
    const found = await Promise.all(uniqueIds.map((id) => this.exerciseRepo.exists(id, viewerId)));
    const missing = uniqueIds.filter((_, i) => !found[i]);
    if (missing.length > 0) {
      throw new HttpError(400, `Unknown exercise ids: ${missing.join(', ')}`);
    }
  }

  // Delete training from repository
  async delete(id: string, ownerId: string | null): Promise<void> {
    await this.requireOwned(id, ownerId);
    await this.trainingRepo.delete(id, ownerId);
  }

  private async requireVisible(id: string, viewerId: string | null): Promise<ITraining> {
    const training = await this.trainingRepo.getById(id, viewerId);
    if (!training) {
      throw new HttpError(404, 'Training not found');
    }
    return training;
  }

  /// El entrenamiento existe Y es del dueño indicado. Ver la explicación en
  /// ExerciseService.requireOwned.
  private async requireOwned(id: string, ownerId: string | null): Promise<ITraining> {
    const training = await this.requireVisible(id, ownerId);
    if ((training.ownerId ?? null) !== ownerId) {
      throw new HttpError(404, 'Training not found');
    }
    return training;
  }

  //  Completar entrenamiento por usuario
  async setCompletedForUser(
    userId: string,
    trainingId: string,
    completed: boolean,
    session: number | null = null,
  ): Promise<IUserTrainingState> {
    // Con su propio uid: puede completar tanto los del catálogo como los suyos.
    const exists = await this.trainingRepo.exists(trainingId, userId);
    if (!exists) {
      throw new HttpError(404, 'Training not found');
    }
    return this.userTrainingStateRepo.setCompleted(userId, trainingId, completed, session);
  }

  // Obtener todos los estados del usuario 
  async getUserTrainingStates(userId: string): Promise<IUserTrainingState[]> {
    return this.userTrainingStateRepo.getAllStates(userId);
  }

  async getAllWithUserState(userId: string): Promise<Array<ITraining & {
    isCompleted: boolean;
    completedAt?: string | null; // ISO
  }>> {
    // Las dos lecturas son independientes → en paralelo, no en secuencia.
    const [trainings, states] = await Promise.all([
      this.getAll(userId),
      this.userTrainingStateRepo.getAllStates(userId),
    ]);

    // Índice por id para cruzar en O(n) en vez de recorrer states por cada training.
    const byId = new Map(states.map(s => [s.trainingId, s]));

    return trainings.map(t => {
      // `id` es opcional en ITraining (no lo lleva al crear), pero lo que sale
      // del repositorio siempre lo tiene.
      const st = t.id ? byId.get(t.id) : undefined;

      const completedAt = st?.completedAt ? st.completedAt.toISOString() : null;
      return {
        ...t,
        isCompleted: !!st?.completedAt,
        completedAt,
      };
    });
  }
}
