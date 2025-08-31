import { ITraining } from '@interfaces/models/ITraining';
import { FirebaseTrainingRepository } from '@repositories/implementations/FirebaseTrainingRepository';

export class TrainingService {
  private repo = new FirebaseTrainingRepository();

  async getAll(): Promise<ITraining[]> {
    return this.repo.getAll();
  }

  async getById(id: string): Promise<ITraining> {
    const training = await this.repo.getById(id);
    if (!training) {
      throw Object.assign(new Error('Training not found'), { status: 404 });
    }
    return training;
  }

  async create(data: ITraining): Promise<string> {
    const trainingData = { ...data, createdAt: new Date(), updatedAt: new Date() };
    return this.repo.create(trainingData);
  }

  async update(id: string, data: Partial<ITraining>): Promise<void> {
    await this.getById(id); // valida existencia
    await this.repo.update(id, data);
  }

  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.repo.delete(id);
  }
}
