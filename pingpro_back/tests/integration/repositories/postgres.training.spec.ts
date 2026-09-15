import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresExerciseRepository } from '../../../src/repositories/implementations/PostgresExerciseRepository';
import { PostgresTrainingRepository } from '../../../src/repositories/implementations/PostgresTrainingRepository';
import { catalogRepositoryContract } from '../../contracts/catalogRepository.contract';
import { trainingFixtures } from '../../contracts/fixtures';
import { resetPostgres, seedExercises } from '../helpers/postgres';

// Todo lo de PostgresTrainingRepository contra la base local pingpro_test.
const pool = createPool();
const EXERCISE_IDS = ['e1', 'e2', 'e3'];

async function resetWithExercises(): Promise<void> {
  await resetPostgres(pool);
  await seedExercises(pool, EXERCISE_IDS);
}

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

catalogRepositoryContract(
  'PostgresTrainingRepository',
  { createRepository: () => new PostgresTrainingRepository(pool), reset: resetWithExercises },
  trainingFixtures,
);

describe('PostgresTrainingRepository (solo Postgres)', () => {
  let repo: PostgresTrainingRepository;

  beforeEach(async () => {
    await resetWithExercises();
    repo = new PostgresTrainingRepository(pool);
  });

  it('conserva el orden y los ejercicios repetidos', async () => {
    const id = await repo.create({ ...trainingFixtures.a, exerciseIds: ['e2', 'e1', 'e2'] });

    await expect(repo.getById(id)).resolves.toMatchObject({ exerciseIds: ['e2', 'e1', 'e2'] });
  });

  it('un ejercicio borrado desaparece de sus entrenamientos', async () => {
    const id = await repo.create({ ...trainingFixtures.a, exerciseIds: ['e1', 'e2', 'e3'] });

    await new PostgresExerciseRepository(pool).delete('e2');

    await expect(repo.getById(id)).resolves.toMatchObject({ exerciseIds: ['e1', 'e3'] });
  });
});
