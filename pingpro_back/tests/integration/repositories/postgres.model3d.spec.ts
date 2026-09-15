import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresModel3DRepository } from '../../../src/repositories/implementations/PostgresModel3DRepository';
import { model3dRepositoryContract } from '../../contracts/model3dRepository.contract';
import { resetPostgres } from '../helpers/postgres';

// PostgresModel3DRepository contra la base local pingpro_test. Es de solo
// lectura, así que el contrato siembra las filas con SQL directo.
const pool = createPool();

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

model3dRepositoryContract('PostgresModel3DRepository', {
  createRepository: () => new PostgresModel3DRepository(pool),
  reset: () => resetPostgres(pool),
  seed: async (models) => {
    for (const model of models) {
      await pool.query(
        'INSERT INTO models_3d (id, name, url, created_at, updated_at) VALUES ($1, $2, $3, $4, $5)',
        [model.id, model.name, model.url, model.createdAt, model.updatedAt],
      );
    }
  },
});
