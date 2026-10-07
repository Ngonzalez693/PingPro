/**
 * Reglas de negocio del perfil de usuario (documento en Firestore).
 *
 * create() exige que el id venga dado: es el uid de Firebase Auth. Nunca se
 * deja que Firestore genere un id automático, porque el uid es la llave que
 * relaciona credencial, perfil y subcolecciones de progreso.
 */
import { IUser } from '../interfaces/models/IUser';
import type { IUserRepository } from '../interfaces/repositories/IUserRepository';
import { HttpError } from '../utils/httpError';
import type { AuthService } from './AuthService';

// De Auth solo hace falta borrar la cuenta. Pick en vez de la clase entera:
// los tests pasan un falso sin arrancar firebase-admin, y `import type` no
// carga config/firebase.
type AccountDeleter = Pick<AuthService, 'deleteUser'>;

export class UserService {
  // Los recibe de src/container.ts: el servicio solo conoce las interfaces.
  constructor(
    private readonly repo: IUserRepository,
    private readonly accounts: AccountDeleter,
  ) {}

  async getById(id: string): Promise<IUser> {
    const user = await this.repo.getById(id);
    if (!user) throw new HttpError(404, "User not found");
    return user;
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

  /**
   * Elimina la cuenta entera: primero la fila de users (todo lo que cuelga de
   * ella se borra en cascada; el catálogo, sin dueño, no se toca) y después la
   * cuenta de Firebase Auth.
   *
   * En ese orden a propósito: si falla Auth, el usuario todavía puede entrar
   * (ya sin datos) y reintentar; al revés quedarían datos que nadie puede
   * borrar. Por eso tampoco se valida que la fila exista: un reintento llega
   * sin ella y tiene que seguir hasta Auth.
   */
  async deleteAccount(uid: string): Promise<void> {
    await this.repo.delete(uid);
    await this.accounts.deleteUser(uid);
  }
}
