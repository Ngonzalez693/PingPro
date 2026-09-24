import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresUserTrainingStateRepository } from '../../../src/repositories/implementations/PostgresUserTrainingStateRepository';
import { userTrainingStateContract } from '../../contracts/userTrainingStateRepository.contract';
import { resetPostgres, seedUsers } from '../helpers/postgres';

// PostgresUserTrainingStateRepository contra la base local pingpro_test: el
// contrato compartido con Firebase y el historial, que solo tiene Postgres.
const pool = createPool();

// Solo este archivo necesita entrenamientos sembrados.
async function seedTrainings(ids: string[]): Promise<void> {
  await pool.query(
    `INSERT INTO trainings (id, name, category, image)
     SELECT id, 'Entrenamiento ' || id, 'Grado', 'assets/images/training_1.jpg'
     FROM unnest($1::text[]) AS id`,
    [ids],
  );
}

// El contrato usa u1, u2, t1 y t2: con claves foráneas tienen que existir.
async function resetWithParents(): Promise<void> {
  await resetPostgres(pool);
  await seedUsers(pool, ['u1', 'u2']);
  await seedTrainings(['t1', 't2']);
}

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

userTrainingStateContract('PostgresUserTrainingStateRepository', {
  createRepository: () => new PostgresUserTrainingStateRepository(pool),
  reset: resetWithParents,
});

describe('PostgresUserTrainingStateRepository (historial)', () => {
  let repo: PostgresUserTrainingStateRepository;

  beforeEach(async () => {
    await resetWithParents();
    repo = new PostgresUserTrainingStateRepository(pool);
  });

  async function completionsOfU1T1(): Promise<number> {
    const { rows } = await pool.query(
      `SELECT count(*)::int AS total FROM training_completions WHERE user_id = 'u1' AND training_id = 't1'`,
    );
    return rows[0].total;
  }

  async function sessionsOfU1T1(): Promise<Array<number | null>> {
    const { rows } = await pool.query<{ session: number | null }>(
      `SELECT session FROM training_completions WHERE user_id = 'u1' AND training_id = 't1' ORDER BY id`,
    );
    return rows.map((row) => row.session);
  }

  it('guarda la sesión de cada finalización y, si no llega, NULL', async () => {
    await repo.setCompleted('u1', 't1', true, 3);
    await repo.setCompleted('u1', 't1', true, null);

    expect(await sessionsOfU1T1()).toEqual([3, null]);
  });

  it('completar dos veces deja dos filas y completedAt es la última', async () => {
    await repo.setCompleted('u1', 't1', true);
    const second = await repo.setCompleted('u1', 't1', true);

    expect(await completionsOfU1T1()).toBe(2);
    await expect(repo.getState('u1', 't1')).resolves.toMatchObject({ completedAt: second.completedAt });
  });

  it('setCompleted(false) deshace solo la última finalización', async () => {
    const first = await repo.setCompleted('u1', 't1', true);
    await repo.setCompleted('u1', 't1', true);

    const undone = await repo.setCompleted('u1', 't1', false);

    expect(await completionsOfU1T1()).toBe(1);
    expect(undone.completedAt).toEqual(first.completedAt);
  });
});
