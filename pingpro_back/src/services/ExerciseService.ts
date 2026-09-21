/**
 * Reglas de negocio de ejercicios. Coordina dos repositorios:
 *  - exerciseRepo:  catálogo compartido (colección 'exercises')
 *  - userStateRepo: progreso privado (users/{uid}/exerciseStates)
 *
 * Es la capa que decide qué es un 404 y qué validaciones cruzadas aplican.
 * Los controllers no hablan nunca con Firestore directamente.
 */
import { IExercise } from '../interfaces/models/IExercise';
import type { IUserExerciseState } from '../interfaces/models/IUserExerciseState';
import type { IExerciseRepository } from '../interfaces/repositories/IExerciseRepository';
import type { IUserExerciseStateRepository } from '../interfaces/repositories/IUserExerciseStateRepository';

export class ExerciseService {
  // Los recibe de src/container.ts: el servicio solo conoce las interfaces.
  constructor(
    private readonly exerciseRepo: IExerciseRepository,
    private readonly userStateRepo: IUserExerciseStateRepository,
  ) {}

  // LISTADO / DETALLE
  //
  // `viewerId` es quién pregunta: ve el catálogo y además sus ejercicios
  // privados. Un ejercicio privado de otro usuario es un 404, no un 403: que
  // no se pueda averiguar que existe.
  async getAll(viewerId: string): Promise<IExercise[]> {
    return this.exerciseRepo.getAll(viewerId);
  }

  async getById(id: string, viewerId: string): Promise<IExercise> {
    return this.requireVisible(id, viewerId);
  }

  // Create exercise from repository
  async create(data: IExercise): Promise<string> {
    return this.exerciseRepo.create(data);
  }

  // Update exercise from repository
  //
  // Las tres operaciones de escritura de aquí son las de admin sobre el
  // catálogo: miran con viewer null para no encontrar nunca un ejercicio
  // privado, ni siquiera uno del propio admin.
  async update(id: string, data: Partial<IExercise>): Promise<void> {
    await this.requireVisible(id, null); // validate existance
    await this.exerciseRepo.update(id, data);
  }

  // Delete exercise from repository
  async delete(id: string): Promise<void> {
    await this.requireVisible(id, null);
    await this.exerciseRepo.delete(id);
  }

  private async requireVisible(id: string, viewerId: string | null): Promise<IExercise> {
    const exercise = await this.exerciseRepo.getById(id, viewerId);
    if (!exercise) {
      throw Object.assign(new Error('Exercise not found'), { status: 404 });
    }
    return exercise;
  }

  // Favorito por USUARIO
  async setFavoriteForUser(
    userId: string,
    exerciseId: string,
    isFavorite: boolean
  ): Promise<IUserExerciseState> {
    // valida que exista el ejercicio (evita estados huérfanos)
    // Sin esta comprobación se podrían crear documentos en
    // users/{uid}/exerciseStates apuntando a ejercicios inexistentes.
    //
    // Mira con el uid del propio usuario: puede marcar como favorito tanto un
    // ejercicio del catálogo como uno suyo privado.
    await this.requireVisible(exerciseId, userId);
    return this.userStateRepo.setFavorite(userId, exerciseId, isFavorite);
  }

  // Completado por USUARIO
  async setCompletedForUser(
    userId: string,
    exerciseId: string,
    completed: boolean
  ): Promise<IUserExerciseState> {
    await this.requireVisible(exerciseId, userId);
    return this.userStateRepo.setCompleted(userId, exerciseId, completed);
  }

  // obtener todos los estados del usuario
  async getUserExerciseStates(userId: string): Promise<IUserExerciseState[]> {
    return this.userStateRepo.getAllStates(userId);
  }
}
