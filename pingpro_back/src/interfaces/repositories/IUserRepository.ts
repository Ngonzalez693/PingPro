import { IUser } from '../models/IUser';

// Interface for user repository
export interface IUserRepository {
  getAll(): Promise<IUser[]>;
  getById(id: string): Promise<IUser | null>;
  getByEmail(email: string): Promise<IUser | null>;
  create(user: IUser): Promise<string>;
  update(id: string, user: Partial<IUser>): Promise<void>;
  delete(id: string): Promise<void>;
}
