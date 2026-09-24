import type { Pool } from 'pg';
import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { recreateSchema, resetPostgres } from '../helpers/postgres';

const CHECK_VIOLATION = '23514';

// El esquema de las migraciones probado con SQL directo, sin repositorios:
// sus restricciones son la última barrera aunque la API ya valide antes.
// Los bloques van en orden: "restricciones" usa el esquema que crea
// "migraciones".
describe('Esquema de Postgres', () => {
  let pool: Pool;

  beforeAll(async () => {
    pool = createPool();
    await recreateSchema(pool);
  });
  afterAll(() => pool.end());

  describe('migraciones', () => {
    it('migrate aplica todas las migraciones en orden en una base vacía', async () => {
      await expect(migrate(pool)).resolves.toEqual([
        '0001_initial_schema',
        '0002_own_zone_and_new_hits',
        '0003_completion_session',
      ]);
    });

    it('migrate otra vez no aplica nada', async () => {
      await expect(migrate(pool)).resolves.toEqual([]);
    });

    it('todas las tablas tienen RLS activado', async () => {
      const { rows } = await pool.query<{ relname: string; relrowsecurity: boolean }>(`
        SELECT c.relname, c.relrowsecurity
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'
        ORDER BY c.relname`);

      // 10 tablas de datos + schema_migrations.
      expect(rows).toHaveLength(11);
      expect(rows.filter((row) => !row.relrowsecurity)).toEqual([]);
    });
  });

  describe('restricciones', () => {
    beforeEach(() => resetPostgres(pool));

    async function insertExercise(category = 'Técnico', ownerId: string | null = null): Promise<string> {
      const { rows } = await pool.query<{ id: string }>(
        `INSERT INTO exercises (owner_id, name, category, image)
         VALUES ($1, 'Topspin', $2, 'assets/images/exercise_1.jpg')
         RETURNING id`,
        [ownerId, category],
      );
      return rows[0].id;
    }

    async function insertStep(exerciseId: string, hit: number): Promise<void> {
      await pool.query(
        `INSERT INTO exercise_steps (exercise_id, position, hit, rotation, zone, direction, side)
         VALUES ($1, 0, $2, 2, 3, 6, 1)`,
        [exerciseId, hit],
      );
    }

    it('genera el id como UUID y guarda las tildes intactas', async () => {
      const id = await insertExercise('Táctico');

      expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
      const { rows } = await pool.query('SELECT category FROM exercises WHERE id = $1', [id]);
      expect(rows[0].category).toBe('Táctico');
    });

    it('rechaza una categoría fuera de la lista', async () => {
      await expect(insertExercise('Ataque')).rejects.toMatchObject({ code: CHECK_VIOLATION });
    });

    it('rechaza un paso con un código fuera de su enum', async () => {
      const id = await insertExercise();

      await expect(insertStep(id, 13)).rejects.toMatchObject({ code: CHECK_VIOLATION });
    });

    it('acepta los golpes nuevos hasta el 12', async () => {
      const id = await insertExercise();

      await expect(insertStep(id, 12)).resolves.toBeUndefined();
    });

    it('un paso sin own_zone queda en 4 (Libre) y fuera de 1..4 se rechaza', async () => {
      const id = await insertExercise();
      await insertStep(id, 1);

      const { rows } = await pool.query('SELECT own_zone FROM exercise_steps WHERE exercise_id = $1', [id]);
      expect(rows[0].own_zone).toBe(4);
      await expect(
        pool.query('UPDATE exercise_steps SET own_zone = 5 WHERE exercise_id = $1', [id]),
      ).rejects.toMatchObject({ code: CHECK_VIOLATION });
    });

    it('borrar un usuario borra en cascada todo lo suyo y deja el catálogo', async () => {
      await pool.query(`INSERT INTO users (id, email) VALUES ('u1', 'ana@test.dev')`);
      const catalogId = await insertExercise();
      const ownId = await insertExercise('Técnico', 'u1');
      await insertStep(ownId, 1);
      await pool.query(
        `INSERT INTO user_exercise_states (user_id, exercise_id, is_favorite) VALUES ('u1', $1, true)`,
        [catalogId],
      );
      await pool.query(`INSERT INTO exercise_completions (user_id, exercise_id) VALUES ('u1', $1)`, [catalogId]);
      const { rows: trainings } = await pool.query<{ id: string }>(
        `INSERT INTO trainings (owner_id, name, category, image)
         VALUES ('u1', 'Mío', 'Grado', 'assets/images/training_1.jpg')
         RETURNING id`,
      );
      await pool.query(
        `INSERT INTO training_exercises (training_id, position, exercise_id) VALUES ($1, 0, $2), ($1, 1, $3)`,
        [trainings[0].id, catalogId, ownId],
      );

      await pool.query(`DELETE FROM users WHERE id = 'u1'`);

      const { rows } = await pool.query(`
        SELECT
          (SELECT count(*) FROM exercises)::int            AS exercises,
          (SELECT count(*) FROM exercise_steps)::int       AS steps,
          (SELECT count(*) FROM trainings)::int            AS trainings,
          (SELECT count(*) FROM training_exercises)::int   AS training_exercises,
          (SELECT count(*) FROM user_exercise_states)::int AS states,
          (SELECT count(*) FROM exercise_completions)::int AS completions`);
      expect(rows[0]).toEqual({
        exercises: 1,
        steps: 0,
        trainings: 0,
        training_exercises: 0,
        states: 0,
        completions: 0,
      });
    });

    it('la sesión de una finalización es NULL por defecto y solo admite 1..3', async () => {
      await pool.query(`INSERT INTO users (id, email) VALUES ('u1', 'ana@test.dev')`);
      const exerciseId = await insertExercise();
      const { rows: trainings } = await pool.query<{ id: string }>(
        `INSERT INTO trainings (name, category, image)
         VALUES ('Calentamiento', 'Grado', 'assets/images/training_1.jpg')
         RETURNING id`,
      );
      const trainingId = trainings[0].id;

      const { rows } = await pool.query<{ session: number | null }>(
        `INSERT INTO exercise_completions (user_id, exercise_id) VALUES ('u1', $1) RETURNING session`,
        [exerciseId],
      );
      expect(rows[0].session).toBeNull();
      await expect(
        pool.query(`INSERT INTO exercise_completions (user_id, exercise_id, session) VALUES ('u1', $1, 3)`, [exerciseId]),
      ).resolves.toBeDefined();
      await expect(
        pool.query(`INSERT INTO exercise_completions (user_id, exercise_id, session) VALUES ('u1', $1, 4)`, [exerciseId]),
      ).rejects.toMatchObject({ code: CHECK_VIOLATION });
      await expect(
        pool.query(`INSERT INTO training_completions (user_id, training_id, session) VALUES ('u1', $1, 0)`, [trainingId]),
      ).rejects.toMatchObject({ code: CHECK_VIOLATION });
    });
  });
});
