/**
 * Contrato de persistencia del perfil de usuario.
 *
 * El id del perfil es siempre el uid de Firebase Auth: por eso solo existe
 * createWithUID y no un create con id automático.
 */
import { IUser } from '../models/IUser';

export interface IUserRepository {
  getById(id: string): Promise<IUser | null>;
  createWithUID(uid: string, user: IUser): Promise<void>;
  update(id: string, user: Partial<IUser>): Promise<void>;
  delete(id: string): Promise<void>;
}
