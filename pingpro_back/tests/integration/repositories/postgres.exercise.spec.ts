import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresExerciseRepository } from '../../../src/repositories/implementations/PostgresExerciseRepository';
import { catalogRepositoryContract } from '../../contracts/catalogRepository.contract';
import { exerciseFixtures } from '../../contracts/fixtures';
import { resetPostgres } from '../helpers/postgres';

// Todo lo de PostgresExerciseRepository contra la base local pingpro_test: el
// contrato compartido con Firebase y lo que solo hace Postgres.
const pool = createPool();

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

catalogRepositoryContract(
  'PostgresExerciseRepository',
  { createRepository: () => new PostgresExerciseRepository(pool), reset: () => resetPostgres(pool) },
  exerciseFixtures,
);

// Borrado lógico, historial y catálogo frente a privados: Firebase no tiene
// nada de esto, así que no va en el contrato compartido.
describe('PostgresExerciseRepository (solo Postgres)', () => {
  let repo: PostgresExerciseRepository;

  beforeEach(async () => {
    await resetPostgres(pool);
    repo = new PostgresExerciseRepository(pool);
  });

  async function insertUser(id: string): Promise<void> {
    await pool.query('INSERT INTO users (id, email) VALUES ($1, $2)', [id, `${id}@test.dev`]);
  }

  it('update con sequence sustituye todos los pasos', async () => {
    const id = await repo.create(exerciseFixtures.b); // 2 pasos

    await repo.update(id, { sequence: exerciseFixtures.a.sequence }); // 1 paso

    await expect(repo.getById(id)).resolves.toMatchObject({ sequence: exerciseFixtures.a.sequence });
    const { rows } = await pool.query('SELECT count(*)::int AS steps FROM exercise_steps WHERE exercise_id = $1', [id]);
    expect(rows[0].steps).toBe(1);
  });

  it('delete es lógico: la fila y su historial se quedan', async () => {
    const id = await repo.create(exerciseFixtures.a);
    await insertUser('u1');
    await pool.query('INSERT INTO exercise_completions (user_id, exercise_id) VALUES ($1, $2)', ['u1', id]);

    await repo.delete(id);

    await expect(repo.getAll()).resolves.toEqual([]);
    const { rows } = await pool.query(
      `SELECT
         (SELECT deleted_at IS NOT NULL FROM exercises WHERE id = $1)            AS deleted,
         (SELECT count(*)::int FROM exercise_completions WHERE exercise_id = $1) AS completions`,
      [id],
    );
    expect(rows[0]).toEqual({ deleted: true, completions: 1 });
  });

  it('update rechaza un ejercicio borrado', async () => {
    const id = await repo.create(exerciseFixtures.a);
    await repo.delete(id);

    await expect(repo.update(id, { name: 'Otro nombre' })).rejects.toThrow('Exercise not found');
  });

  it('los ejercicios privados no aparecen en el catálogo', async () => {
    await insertUser('u1');
    const { rows } = await pool.query<{ id: string }>(
      `INSERT INTO exercises (owner_id, name, category, image)
       VALUES ('u1', 'Mío', 'Técnico', 'assets/images/exercise_1.jpg')
       RETURNING id`,
    );

    await expect(repo.getAll()).resolves.toEqual([]);
    await expect(repo.getById(rows[0].id)).resolves.toBeNull();
    await expect(repo.exists(rows[0].id)).resolves.toBe(false);
  });
});
