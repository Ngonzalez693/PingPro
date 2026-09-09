/**
 * Reglas de negocio de ejercicios. Coordina dos repositorios:
 *  - exerciseRepo:  catálogo compartido (colección 'exercises')
 *  - userStateRepo: progreso privado (users/{uid}/exerciseStates)
 *
 * Es la capa que decide qué es un 404 y qué validaciones cruzadas aplican.
 * Los controllers no hablan nunca con Firestore directamente.
 */
import { IExercise } from '@interfaces/models/IExercise';
import { FirebaseExerciseRepository } from '@repositories/implementations/FirebaseExerciseRepository';
import FirebaseUserExerciseStateRepository from '@repositories/implementations/FirebaseUserExerciseStateRepository';
import type { IUserExerciseState } from '@interfaces/models/IUserExerciseState';

export class ExerciseService {
  private exerciseRepo = new FirebaseExerciseRepository();
  private userStateRepo = new FirebaseUserExerciseStateRepository();

  // LISTADO / DETALLE 
  async getAll(): Promise<IExercise[]> {
    return this.exerciseRepo.getAll();
  }

  async getById(id: string): Promise<IExercise> {
    const exercise = await this.exerciseRepo.getById(id);
    if (!exercise) {
      throw Object.assign(new Error('Exercise not found'), { status: 404 });
    }
    return exercise;
  }

  // Create exercise from repository
  async create(data: IExercise): Promise<string> {
    return this.exerciseRepo.create(data);
  }

  // Update exercise from repository
  async update(id: string, data: Partial<IExercise>): Promise<void> {
    await this.getById(id); // validate existance
    await this.exerciseRepo.update(id, data);
  }

  // Delete exercise from repository
  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.exerciseRepo.delete(id);
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
    await this.getById(exerciseId);
    return this.userStateRepo.setFavorite(userId, exerciseId, isFavorite);
  }

  // Completado por USUARIO
  async setCompletedForUser(
    userId: string,
    exerciseId: string,
    completed: boolean
  ): Promise<IUserExerciseState> {
    await this.getById(exerciseId);
    return this.userStateRepo.setCompleted(userId, exerciseId, completed);
  }

  // obtener todos los estados del usuario
  async getUserExerciseStates(userId: string): Promise<IUserExerciseState[]> {
    return this.userStateRepo.getAllStates(userId);
  }
}
