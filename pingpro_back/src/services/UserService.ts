/**
 * Reglas de negocio del perfil de usuario (documento en Firestore).
 *
 * create() exige que el id venga dado: es el uid de Firebase Auth. Nunca se
 * deja que Firestore genere un id automático, porque el uid es la llave que
 * relaciona credencial, perfil y subcolecciones de progreso.
 */
import { IUser } from '@interfaces/models/IUser';
import { FirebaseUserRepository } from '@repositories/implementations/FirebaseUserRepository';

export class UserService {
  private repo = new FirebaseUserRepository();

  async getAll(): Promise<IUser[]> {
    return this.repo.getAll();
  }

  async getById(id: string): Promise<IUser> {
    const user = await this.repo.getById(id);
    if (!user) throw Object.assign(new Error("User not found"), { status: 404 });
    return user;
  }

  async getByEmail(email: string): Promise<IUser | null> {
    return this.repo.getByEmail(email);
  }

  async create(data: IUser): Promise<void> {
    if (!data.id) throw new Error("User id (UID) required for creation");
    return this.repo.createWithUID(data.id, data);
  }

  async update(id: string, data: Partial<IUser>): Promise<void> {
    await this.getById(id); // validar existencia
    await this.repo.update(id, data);
  }

  async delete(id: string): Promise<void> {
    await this.getById(id); // validar existencia
    await this.repo.delete(id);
  }
}
