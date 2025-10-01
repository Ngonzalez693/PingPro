import { IExercise } from '@interfaces/models/IExercise';
import { FirebaseExerciseRepository } from '@repositories/implementations/FirebaseExerciseRepository';

export class ExerciseService {
  private repo = new FirebaseExerciseRepository(); // Object type repository

  // Get all exercises from repository
  async getAll(): Promise<IExercise[]> {
    return this.repo.getAll();
  }

  // Get exercises by id from repository
  async getById(id: string): Promise<IExercise> {
    const exercise = await this.repo.getById(id);
    if (!exercise) {
      throw Object.assign(new Error('Exercise not found'), { status: 404 });
    }
    return exercise;
  }

  // Create exercise from repository
  async create(data: IExercise): Promise<string> {
    return this.repo.create(data);
  }

  // Update exercise from repository
  async update(id: string, data: Partial<IExercise>): Promise<void> {
    await this.getById(id); // validate existance
    await this.repo.update(id, data);
  }

  // Delete exercise from repository
  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.repo.delete(id);
  }

  // Set exercise as favorite or not
  async setFavorite(id: string, isFavorite: boolean): Promise<void> {
    await this.getById(id); // validate existance
    await this.repo.setFavorite(id, isFavorite);
  }

    // Marcar ejercicio como completado o no, según el booleano
  async setCompleted(id: string, completed: boolean): Promise<void> {
    await this.getById(id); // validar existencia
    const completedAt = completed ? new Date() : null;
    await this.repo.setCompleted(id, completedAt);
  }
}
