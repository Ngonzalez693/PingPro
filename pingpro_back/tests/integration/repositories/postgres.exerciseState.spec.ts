import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { PostgresUserExerciseStateRepository } from '../../../src/repositories/implementations/PostgresUserExerciseStateRepository';
import { userExerciseStateContract } from '../../contracts/userExerciseStateRepository.contract';
import { resetPostgres, seedExercises, seedUsers } from '../helpers/postgres';

// PostgresUserExerciseStateRepository contra la base local pingpro_test: el
// contrato compartido con Firebase y el historial, que solo tiene Postgres.
const pool = createPool();

// El contrato usa u1, u2, e1 y e2: con claves foráneas tienen que existir.
async function resetWithParents(): Promise<void> {
  await resetPostgres(pool);
  await seedUsers(pool, ['u1', 'u2']);
  await seedExercises(pool, ['e1', 'e2']);
}

beforeAll(() => migrate(pool));
afterAll(() => pool.end());

userExerciseStateContract('PostgresUserExerciseStateRepository', {
  createRepository: () => new PostgresUserExerciseStateRepository(pool),
  reset: resetWithParents,
});

describe('PostgresUserExerciseStateRepository (historial)', () => {
  let repo: PostgresUserExerciseStateRepository;

  beforeEach(async () => {
    await resetWithParents();
    repo = new PostgresUserExerciseStateRepository(pool);
  });

  async function completionsOfU1E1(): Promise<number> {
    const { rows } = await pool.query(
      `SELECT count(*)::int AS total FROM exercise_completions WHERE user_id = 'u1' AND exercise_id = 'e1'`,
    );
    return rows[0].total;
  }

  async function sessionsOfU1E1(): Promise<Array<number | null>> {
    const { rows } = await pool.query<{ session: number | null }>(
      `SELECT session FROM exercise_completions WHERE user_id = 'u1' AND exercise_id = 'e1' ORDER BY id`,
    );
    return rows.map((row) => row.session);
  }

  it('guarda la sesión de cada finalización y, si no llega, NULL', async () => {
    await repo.setCompleted('u1', 'e1', true, 2);
    await repo.setCompleted('u1', 'e1', true);

    expect(await sessionsOfU1E1()).toEqual([2, null]);
  });

  it('completar dos veces deja dos filas y completedAt es la última', async () => {
    await repo.setCompleted('u1', 'e1', true);
    const second = await repo.setCompleted('u1', 'e1', true);

    expect(await completionsOfU1E1()).toBe(2);
    await expect(repo.getState('u1', 'e1')).resolves.toMatchObject({ completedAt: second.completedAt });
  });

  it('setCompleted(false) deshace solo la última finalización', async () => {
    const first = await repo.setCompleted('u1', 'e1', true);
    await repo.setCompleted('u1', 'e1', true);

    const undone = await repo.setCompleted('u1', 'e1', false);

    expect(await completionsOfU1E1()).toBe(1);
    expect(undone.completedAt).toEqual(first.completedAt);
  });
});
