import { IUser } from '@interfaces/models/IUser';
import { FirebaseUserRepository } from '@repositories/implementations/FirebaseUserRepository';

export class UserService {
  private repo = new FirebaseUserRepository();

  async getAll(): Promise<IUser[]> {
    return this.repo.getAll();
  }

  async getById(id: string): Promise<IUser> {
    const user = await this.repo.getById(id);
    if (!user) throw Object.assign(new Error('User not found'), { status: 404 });
    return user;
  }

  async getByEmail(email: string): Promise<IUser | null> {
    return this.repo.getByEmail(email);
  }

  async create(data: IUser): Promise<string> {
    return this.repo.create(data);
  }

  async update(id: string, data: Partial<IUser>): Promise<void> {
    await this.getById(id);
    await this.repo.update(id, data);
  }

  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.repo.delete(id);
  }
}
