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
    const id = await repo.create(exerciseFixtures.b, null); // 2 pasos

    await repo.update(id, { sequence: exerciseFixtures.a.sequence }, null); // 1 paso

    await expect(repo.getById(id, null)).resolves.toMatchObject({ sequence: exerciseFixtures.a.sequence });
    const { rows } = await pool.query('SELECT count(*)::int AS steps FROM exercise_steps WHERE exercise_id = $1', [id]);
    expect(rows[0].steps).toBe(1);
  });

  it('delete es lógico: la fila y su historial se quedan', async () => {
    const id = await repo.create(exerciseFixtures.a, null);
    await insertUser('u1');
    await pool.query('INSERT INTO exercise_completions (user_id, exercise_id) VALUES ($1, $2)', ['u1', id]);

    await repo.delete(id, null);

    await expect(repo.getAll(null)).resolves.toEqual([]);
    const { rows } = await pool.query(
      `SELECT
         (SELECT deleted_at IS NOT NULL FROM exercises WHERE id = $1)            AS deleted,
         (SELECT count(*)::int FROM exercise_completions WHERE exercise_id = $1) AS completions`,
      [id],
    );
    expect(rows[0]).toEqual({ deleted: true, completions: 1 });
  });

  it('update rechaza un ejercicio borrado', async () => {
    const id = await repo.create(exerciseFixtures.a, null);
    await repo.delete(id, null);

    await expect(repo.update(id, { name: 'Otro nombre' }, null)).rejects.toThrow('Exercise not found');
  });

  // Inserta un ejercicio privado por SQL: todavía no hay forma de crearlo por
  // la API, eso llega con las rutas de escritura.
  async function insertPrivateExercise(ownerId: string, name: string): Promise<string> {
    const { rows } = await pool.query<{ id: string }>(
      `INSERT INTO exercises (owner_id, name, category, image)
       VALUES ($1, $2, 'Técnico', 'assets/images/exercise_1.jpg')
       RETURNING id`,
      [ownerId, name],
    );
    return rows[0].id;
  }

  it('los ejercicios privados no aparecen en el catálogo', async () => {
    await insertUser('u1');
    const id = await insertPrivateExercise('u1', 'Mío');

    await expect(repo.getAll(null)).resolves.toEqual([]);
    await expect(repo.getById(id, null)).resolves.toBeNull();
    await expect(repo.exists(id, null)).resolves.toBe(false);
  });

  it('el dueño sí ve su ejercicio privado', async () => {
    await insertUser('u1');
    const id = await insertPrivateExercise('u1', 'Mío');

    await expect(repo.getById(id, 'u1')).resolves.toMatchObject({ id, name: 'Mío', ownerId: 'u1' });
    await expect(repo.exists(id, 'u1')).resolves.toBe(true);
    await expect(repo.getAll('u1')).resolves.toHaveLength(1);
  });

  it('un usuario no ve los ejercicios privados de otro', async () => {
    await insertUser('u1');
    await insertUser('u2');
    const id = await insertPrivateExercise('u1', 'De u1');

    await expect(repo.getById(id, 'u2')).resolves.toBeNull();
    await expect(repo.exists(id, 'u2')).resolves.toBe(false);
    await expect(repo.getAll('u2')).resolves.toEqual([]);
  });

  it('el listado del dueño es el catálogo más lo suyo, y nada de otros', async () => {
    await insertUser('u1');
    await insertUser('u2');
    await repo.create(exerciseFixtures.a, null); // catálogo
    await insertPrivateExercise('u1', 'De u1');
    await insertPrivateExercise('u2', 'De u2');

    const mine = await repo.getAll('u1');

    expect(mine.map((e) => e.name).sort()).toEqual([exerciseFixtures.a.name, 'De u1'].sort());
  });

  it('un ejercicio del catálogo no lleva ownerId', async () => {
    const id = await repo.create(exerciseFixtures.a, null);

    const exercise = await repo.getById(id, 'u1');

    expect(exercise).not.toHaveProperty('ownerId');
  });

  it('las escrituras de catálogo no tocan un ejercicio privado', async () => {
    await insertUser('u1');
    const id = await insertPrivateExercise('u1', 'Mío');

    await expect(repo.update(id, { name: 'Pisado' }, null)).rejects.toThrow('Exercise not found');
    await repo.delete(id, null);

    await expect(repo.getById(id, 'u1')).resolves.toMatchObject({ name: 'Mío' });
  });
});
