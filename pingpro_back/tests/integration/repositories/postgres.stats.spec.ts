import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresStatsRepository } from '../../../src/repositories/implementations/PostgresStatsRepository';
import { resetPostgres, seedUsers } from '../helpers/postgres';

// PostgresStatsRepository contra la base local pingpro_test. Las fechas se
// fijan a mano para controlar el filtro `from` y el orden.
const pool = createPool();

const FROM = new Date('2026-09-01T00:00:00.000Z');
const BEFORE_FROM = new Date('2026-08-31T23:59:00.000Z');
const DAY_1 = new Date('2026-09-02T10:00:00.000Z');
const DAY_2 = new Date('2026-09-03T18:30:00.000Z');

interface ContentOptions {
  ownerId?: string | null;
  deleted?: boolean;
  createdAt?: Date;
}

async function insertExercise(id: string, category: string, options: ContentOptions = {}): Promise<void> {
  await pool.query(
    `INSERT INTO exercises (id, owner_id, name, category, image, created_at, deleted_at)
     VALUES ($1, $2, 'Ejercicio ' || $1, $3, 'assets/images/exercise_1.jpg', $4, $5)`,
    [id, options.ownerId ?? null, category, options.createdAt ?? DAY_1, options.deleted ? DAY_2 : null],
  );
}

async function insertStep(exerciseId: string, position: number, hit: number, rotation: number): Promise<void> {
  await pool.query(
    `INSERT INTO exercise_steps (exercise_id, position, hit, rotation, zone, direction, side)
     VALUES ($1, $2, $3, $4, 3, 6, 1)`,
    [exerciseId, position, hit, rotation],
  );
}

async function insertTraining(id: string, duration: number | null, options: ContentOptions = {}): Promise<void> {
  await pool.query(
    `INSERT INTO trainings (id, owner_id, name, category, image, duration, created_at, deleted_at)
     VALUES ($1, $2, 'Entrenamiento ' || $1, 'Grado', 'assets/images/training_1.jpg', $3, $4, $5)`,
    [id, options.ownerId ?? null, duration, options.createdAt ?? DAY_1, options.deleted ? DAY_2 : null],
  );
}

async function completeExercise(userId: string, exerciseId: string, at: Date, session: number | null = null): Promise<void> {
  await pool.query(
    'INSERT INTO exercise_completions (user_id, exercise_id, completed_at, session) VALUES ($1, $2, $3, $4)',
    [userId, exerciseId, at, session],
  );
}

async function completeTraining(userId: string, trainingId: string, at: Date, session: number | null = null): Promise<void> {
  await pool.query(
    'INSERT INTO training_completions (user_id, training_id, completed_at, session) VALUES ($1, $2, $3, $4)',
    [userId, trainingId, at, session],
  );
}

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

describe('PostgresStatsRepository', () => {
  let repo: PostgresStatsRepository;

  beforeEach(async () => {
    await resetPostgres(pool);
    await seedUsers(pool, ['u1', 'u2']);
    repo = new PostgresStatsRepository(pool);
  });

  it('sin actividad devuelve las tres listas vacías', async () => {
    await expect(repo.getEvents('u1', FROM)).resolves.toEqual({
      exerciseCompletions: [],
      trainingCompletions: [],
      created: [],
    });
  });

  it('devuelve cada repetición con su sesión, categoría y códigos distintos y ordenados', async () => {
    await insertExercise('e1', 'Técnico');
    await insertStep('e1', 0, 4, 2);
    await insertStep('e1', 1, 1, 2);
    await insertStep('e1', 2, 4, 1);
    await completeExercise('u1', 'e1', DAY_2, 2);
    await completeExercise('u1', 'e1', DAY_1);

    const { exerciseCompletions } = await repo.getEvents('u1', FROM);

    expect(exerciseCompletions).toEqual([
      { exerciseId: 'e1', completedAt: DAY_1, session: null, category: 'Técnico', hits: [1, 4], rotations: [1, 2], deleted: false },
      { exerciseId: 'e1', completedAt: DAY_2, session: 2, category: 'Técnico', hits: [1, 4], rotations: [1, 2], deleted: false },
    ]);
  });

  it('incluye las finalizaciones de un ejercicio borrado y uno sin pasos da listas vacías', async () => {
    await insertExercise('e1', 'Footwork', { deleted: true });
    await completeExercise('u1', 'e1', DAY_1, 1);

    const { exerciseCompletions } = await repo.getEvents('u1', FROM);

    expect(exerciseCompletions).toEqual([
      { exerciseId: 'e1', completedAt: DAY_1, session: 1, category: 'Footwork', hits: [], rotations: [], deleted: true },
    ]);
  });

  it('filtra por usuario y por fecha desde `from`', async () => {
    await insertExercise('e1', 'Táctico');
    await insertTraining('t1', 30);
    await completeExercise('u1', 'e1', BEFORE_FROM);
    await completeExercise('u2', 'e1', DAY_1);
    await completeTraining('u1', 't1', BEFORE_FROM);
    await completeTraining('u2', 't1', DAY_1);

    await expect(repo.getEvents('u1', FROM)).resolves.toEqual({
      exerciseCompletions: [],
      trainingCompletions: [],
      created: [],
    });
  });

  it('devuelve los entrenamientos completados con su sesión y duración, también borrados', async () => {
    await insertTraining('t1', 45);
    await insertTraining('t2', null, { deleted: true });
    await completeTraining('u1', 't1', DAY_2, 3);
    await completeTraining('u1', 't2', DAY_1);

    const { trainingCompletions } = await repo.getEvents('u1', FROM);

    expect(trainingCompletions).toEqual([
      { trainingId: 't2', completedAt: DAY_1, session: null, duration: null },
      { trainingId: 't1', completedAt: DAY_2, session: 3, duration: 45 },
    ]);
  });

  it('creados: solo lo propio, sin borrar y desde `from`', async () => {
    await insertExercise('mine-e', 'Técnico', { ownerId: 'u1', createdAt: DAY_2 });
    await insertTraining('mine-t', 20, { ownerId: 'u1', createdAt: DAY_1 });
    await insertExercise('mine-deleted', 'Técnico', { ownerId: 'u1', deleted: true });
    await insertExercise('mine-old', 'Técnico', { ownerId: 'u1', createdAt: BEFORE_FROM });
    await insertExercise('catalog', 'Técnico');
    await insertTraining('other', 20, { ownerId: 'u2' });

    const { created } = await repo.getEvents('u1', FROM);

    expect(created).toEqual([
      { kind: 'training', id: 'mine-t', createdAt: DAY_1 },
      { kind: 'exercise', id: 'mine-e', createdAt: DAY_2 },
    ]);
  });
});
