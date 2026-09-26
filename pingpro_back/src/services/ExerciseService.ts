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
import { HttpError } from '../utils/httpError';

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

  // ESCRITURAS
  //
  // `ownerId` dice sobre qué lado se escribe: null es el catálogo (rutas de
  // admin) y un uid son los ejercicios privados de ese usuario (rutas /me).
  // Las rutas ya deciden cuál toca; aquí solo se respeta.

  // Create exercise from repository
  async create(data: IExercise, ownerId: string | null): Promise<string> {
    return this.exerciseRepo.create(data, ownerId);
  }

  // Update exercise from repository
  async update(id: string, data: Partial<IExercise>, ownerId: string | null): Promise<void> {
    await this.requireOwned(id, ownerId); // validate existance
    await this.exerciseRepo.update(id, data, ownerId);
  }

  // Delete exercise from repository
  async delete(id: string, ownerId: string | null): Promise<void> {
    await this.requireOwned(id, ownerId);
    await this.exerciseRepo.delete(id, ownerId);
  }

  private async requireVisible(id: string, viewerId: string | null): Promise<IExercise> {
    const exercise = await this.exerciseRepo.getById(id, viewerId);
    if (!exercise) {
      throw new HttpError(404, 'Exercise not found');
    }
    return exercise;
  }

  /// El ejercicio existe Y es del dueño indicado.
  ///
  /// La lectura con viewer trae catálogo + lo del usuario, así que hace falta
  /// la segunda comprobación: sin ella, un usuario podría editar por /me un
  /// ejercicio del catálogo. El repositorio tampoco lo dejaría, pero fallaría
  /// como un error de escritura en vez de como un 404 limpio.
  private async requireOwned(id: string, ownerId: string | null): Promise<IExercise> {
    const exercise = await this.requireVisible(id, ownerId);
    if ((exercise.ownerId ?? null) !== ownerId) {
      throw new HttpError(404, 'Exercise not found');
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
    completed: boolean,
    session: number | null = null,
  ): Promise<IUserExerciseState> {
    await this.requireVisible(exerciseId, userId);
    return this.userStateRepo.setCompleted(userId, exerciseId, completed, session);
  }

  // obtener todos los estados del usuario
  async getUserExerciseStates(userId: string): Promise<IUserExerciseState[]> {
    return this.userStateRepo.getAllStates(userId);
  }
}
