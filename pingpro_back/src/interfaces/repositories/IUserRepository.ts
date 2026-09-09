/**
 * Contrato de persistencia del perfil de usuario.
 *
 * Tiene dos formas de crear a propósito: create() deja que Firestore genere el
 * id, createWithUID() lo fija al uid de Firebase Auth. Para usuarios reales
 * siempre se usa la segunda.
 */
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
