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

  async function insertUser(id: string): Promise<void> {
    await pool.query('INSERT INTO users (id, email) VALUES ($1, $2)', [id, `${id}@test.dev`]);
  }

  // Por SQL: crear entrenamientos privados por la API llega con las rutas de
  // escritura.
  async function insertPrivateTraining(ownerId: string, name: string): Promise<string> {
    const { rows } = await pool.query<{ id: string }>(
      `INSERT INTO trainings (owner_id, name, category, image)
       VALUES ($1, $2, 'Grado', 'assets/images/training_1.jpg')
       RETURNING id`,
      [ownerId, name],
    );
    return rows[0].id;
  }

  it('conserva el orden y los ejercicios repetidos', async () => {
    const id = await repo.create({ ...trainingFixtures.a, exerciseIds: ['e2', 'e1', 'e2'] }, null);

    await expect(repo.getById(id, null)).resolves.toMatchObject({ exerciseIds: ['e2', 'e1', 'e2'] });
  });

  it('un ejercicio borrado desaparece de sus entrenamientos', async () => {
    const id = await repo.create({ ...trainingFixtures.a, exerciseIds: ['e1', 'e2', 'e3'] }, null);

    await new PostgresExerciseRepository(pool).delete('e2', null);

    await expect(repo.getById(id, null)).resolves.toMatchObject({ exerciseIds: ['e1', 'e3'] });
  });

  it('los entrenamientos privados no aparecen en el catálogo', async () => {
    await insertUser('u1');
    const id = await insertPrivateTraining('u1', 'Mío');

    await expect(repo.getAll(null)).resolves.toEqual([]);
    await expect(repo.getById(id, null)).resolves.toBeNull();
    await expect(repo.exists(id, null)).resolves.toBe(false);
  });

  it('el dueño sí ve su entrenamiento privado', async () => {
    await insertUser('u1');
    const id = await insertPrivateTraining('u1', 'Mío');

    await expect(repo.getById(id, 'u1')).resolves.toMatchObject({ id, name: 'Mío', ownerId: 'u1' });
    await expect(repo.exists(id, 'u1')).resolves.toBe(true);
  });

  it('un usuario no ve los entrenamientos privados de otro', async () => {
    await insertUser('u1');
    await insertUser('u2');
    const id = await insertPrivateTraining('u1', 'De u1');

    await expect(repo.getById(id, 'u2')).resolves.toBeNull();
    await expect(repo.getAll('u2')).resolves.toEqual([]);
  });

  it('el listado del dueño es el catálogo más lo suyo', async () => {
    await insertUser('u1');
    await insertUser('u2');
    await repo.create(trainingFixtures.a, null); // catálogo
    await insertPrivateTraining('u1', 'De u1');
    await insertPrivateTraining('u2', 'De u2');

    const mine = await repo.getAll('u1');

    expect(mine.map((t) => t.name).sort()).toEqual([trainingFixtures.a.name, 'De u1'].sort());
  });

  it('las escrituras de catálogo no tocan un entrenamiento privado', async () => {
    await insertUser('u1');
    const id = await insertPrivateTraining('u1', 'Mío');

    await expect(repo.update(id, { name: 'Pisado' }, null)).rejects.toThrow('Training not found');
    await repo.delete(id, null);

    await expect(repo.getById(id, 'u1')).resolves.toMatchObject({ name: 'Mío' });
  });
});
