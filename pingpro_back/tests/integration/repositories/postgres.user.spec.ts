import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresUserRepository } from '../../../src/repositories/implementations/PostgresUserRepository';
import { userRepositoryContract } from '../../contracts/userRepository.contract';
import { resetPostgres } from '../helpers/postgres';

// PostgresUserRepository contra la base local pingpro_test. El borrado en
// cascada de un usuario ya lo prueba postgres.schema.spec.ts.
const pool = createPool();

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

userRepositoryContract('PostgresUserRepository', {
  createRepository: () => new PostgresUserRepository(pool),
  reset: () => resetPostgres(pool),
});
