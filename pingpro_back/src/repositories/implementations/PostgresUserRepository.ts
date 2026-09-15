/**
 * Implementación en Postgres de IUserRepository (tabla users).
 *
 * El id es el uid de Firebase Auth. Las fechas que escribe el repositorio salen
 * del reloj de Node (new Date()), como en Firestore: la hora la pone la API.
 * Borrar un usuario borra en cascada todo lo suyo (estados, historial y
 * contenido privado): es el borrado de cuenta que exigen las tiendas.
 */
import type { Pool } from 'pg';
import type { IUser } from '../../interfaces/models/IUser';
import type { IUserRepository } from '../../interfaces/repositories/IUserRepository';

interface UserRow {
  id: string;
  email: string;
  display_name: string | null;
  photo_url: string | null;
  roles: string[] | null;
  created_at: Date;
  updated_at: Date;
}

// Los contratos comparan con toEqual: un NULL de la base es un campo ausente.
function toUser(row: UserRow): IUser {
  return {
    id: row.id,
    email: row.email,
    ...(row.display_name === null ? {} : { displayName: row.display_name }),
    ...(row.photo_url === null ? {} : { photoURL: row.photo_url }),
    ...(row.roles === null ? {} : { roles: row.roles }),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class PostgresUserRepository implements IUserRepository {
  constructor(private readonly pool: Pool) {}

  async getById(id: string): Promise<IUser | null> {
    const { rows } = await this.pool.query<UserRow>(
      `SELECT id, email, display_name, photo_url, roles, created_at, updated_at
       FROM users
       WHERE id = $1`,
      [id],
    );
    return rows.length > 0 ? toUser(rows[0]) : null;
  }

  async createWithUID(uid: string, user: IUser): Promise<void> {
    const now = new Date();
    await this.pool.query(
      `INSERT INTO users (id, email, display_name, photo_url, roles, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        uid,
        user.email,
        user.displayName ?? null,
        user.photoURL ?? null,
        user.roles ?? null,
        user.createdAt ?? now,
        user.updatedAt ?? now,
      ],
    );
  }

  // COALESCE: lo que no viene en el patch conserva su valor, como update() de
  // Firestore.
  async update(id: string, user: Partial<IUser>): Promise<void> {
    const { rowCount } = await this.pool.query(
      `UPDATE users
       SET email        = COALESCE($2, email),
           display_name = COALESCE($3, display_name),
           photo_url    = COALESCE($4, photo_url),
           roles        = COALESCE($5, roles),
           updated_at   = $6
       WHERE id = $1`,
      [id, user.email ?? null, user.displayName ?? null, user.photoURL ?? null, user.roles ?? null, new Date()],
    );
    if (rowCount === 0) {
      throw new Error(`User not found: ${id}`);
    }
  }

  async delete(id: string): Promise<void> {
    await this.pool.query('DELETE FROM users WHERE id = $1', [id]);
  }
}
