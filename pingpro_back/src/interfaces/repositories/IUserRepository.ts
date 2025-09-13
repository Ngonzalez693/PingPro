// Interface for user repository
import { IUser } from '../models/IUser';

export interface IUserRepository {
  getAll(): Promise<IUser[]>;
  getById(id: string): Promise<IUser | null>;
  getByEmail(email: string): Promise<IUser | null>;
  create(user: IUser): Promise<string>; // ID del usuario creado 
  createWithUID(uid: string, user: IUser): Promise<void>; // crea con UID especificado
  update(id: string, user: Partial<IUser>): Promise<void>;
  delete(id: string): Promise<void>;
}
