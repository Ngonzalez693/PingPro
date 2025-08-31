import { IExercise } from '@interfaces/models/IExercise';
import { FirebaseExerciseRepository } from '@repositories/implementations/FirebaseExerciseRepository';

export class ExerciseService {
  private repo = new FirebaseExerciseRepository();

  async getAll(): Promise<IExercise[]> {
    return this.repo.getAll();
  }

  async getById(id: string): Promise<IExercise> {
    const exercise = await this.repo.getById(id);
    if (!exercise) {
      throw Object.assign(new Error('Exercise not found'), { status: 404 });
    }
    return exercise;
  }

  async create(data: IExercise): Promise<string> {
    return this.repo.create(data);
  }

  async update(id: string, data: Partial<IExercise>): Promise<void> {
    await this.getById(id); // valida existencia
    await this.repo.update(id, data);
  }

  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.repo.delete(id);
  }
}
