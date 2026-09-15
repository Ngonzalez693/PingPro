/**
 * Implementación en Postgres de IModel3DRepository (tabla models_3d). Solo
 * lectura: las filas se cargan fuera de la API, igual que los .glb.
 */
import type { Pool } from 'pg';
import type { IModel3D } from '../../interfaces/models/IModel3D';
import type { IModel3DRepository } from '../../interfaces/repositories/IModel3DRepository';

const SELECT_MODELS = `
  SELECT id, name, url, created_at AS "createdAt", updated_at AS "updatedAt"
  FROM models_3d`;

export class PostgresModel3DRepository implements IModel3DRepository {
  constructor(private readonly pool: Pool) {}

  async getAll(): Promise<IModel3D[]> {
    const { rows } = await this.pool.query<IModel3D>(`${SELECT_MODELS} ORDER BY created_at DESC`);
    return rows;
  }

  async getById(id: string): Promise<IModel3D | null> {
    const { rows } = await this.pool.query<IModel3D>(`${SELECT_MODELS} WHERE id = $1`, [id]);
    return rows[0] ?? null;
  }
}
