import { getAuth } from 'firebase-admin/auth';
import type { Pool } from 'pg';
import { db } from '../../../src/config/firebase';
import { createPool } from '../../../src/config/postgres';
import { migrate } from '../../../src/db/migrate';
import { insertMissingUsers, loadRows } from '../../../src/migration/load';
import { buildMigrationPlan } from '../../../src/migration/plan';
import { readFirestoreSnapshot } from '../../../src/migration/readFirestore';
import { clearAuth, clearFirestore, closeFirebaseApp } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

// De punta a punta: se siembra el emulador de Firestore, se lee, se arma el
// plan y se carga en la base local pingpro_test.
const NOW = new Date('2026-09-15T10:00:00.000Z');
const COMPLETED = new Date('2026-09-10T08:00:00.000Z');
const step = { hit: 1, rotation: 2, zone: 3, direction: 6, side: 1 };

describe('Migración de Firestore a Postgres (emuladores → pingpro_test)', () => {
  const pool: Pool = createPool();

  beforeAll(() => migrate(pool));
  afterAll(async () => {
    await pool.end();
    await closeFirebaseApp();
  });

  beforeEach(async () => {
    await Promise.all([clearFirestore(), clearAuth(), resetPostgres(pool)]);
  });

  async function seedFirestore(): Promise<void> {
    await getAuth().createUser({ uid: 'u1', email: 'ana@test.dev', password: 'Abc12345' });
    await db.collection('users').doc('u1').set({ email: 'ana@test.dev', displayName: 'Ana', roles: ['user'] });
    // isFavorite suelto: el plan lo avisa y no lo migra.
    await db
      .collection('exercises')
      .doc('e1')
      .set({ name: 'Topspin', category: 'Técnico', image: 'a.jpg', sequence: [step], isFavorite: true });
    // e9 no existe: se descarta y se lista.
    await db
      .collection('trainings')
      .doc('t1')
      .set({ name: 'Calentamiento', category: 'Grado', image: 't.jpg', exerciseIds: ['e1', 'e9'], duration: 20 });
    await db.collection('model3d').doc('m1').set({ name: 'Forehand Topspin', url: 'https://example.com/m1.glb' });
    await db
      .collection('users')
      .doc('u1')
      .collection('exerciseStates')
      .doc('e1')
      .set({ isFavorite: true, completedAt: COMPLETED, updatedAt: COMPLETED });
    // Estado colgado de un usuario sin documento: Firestore lo permite, y por
    // eso los estados se leen con collectionGroup.
    await db.collection('users').doc('u9').collection('trainingStates').doc('t1').set({ completedAt: COMPLETED });
  }

  async function planFromFirestore() {
    return buildMigrationPlan(await readFirestoreSnapshot(), NOW);
  }

  it('lee Firestore, marca los problemas y carga todo en Postgres', async () => {
    await seedFirestore();

    const plan = await planFromFirestore();
    await loadRows(pool, plan.rows, { replace: false });

    expect(plan.problems.map((problem) => [problem.kind, problem.path])).toEqual([
      ['warning', 'exercises/e1'],
      ['discarded', 'trainings/t1'],
      ['discarded', 'users/u9/trainingStates/t1'],
    ]);
    const { rows } = await pool.query(`
      SELECT
        (SELECT count(*)::int FROM users)                AS users,
        (SELECT count(*)::int FROM exercise_steps)       AS steps,
        (SELECT count(*)::int FROM training_exercises)   AS training_exercises,
        (SELECT count(*)::int FROM exercise_completions) AS completions,
        (SELECT count(*)::int FROM models_3d)            AS models`);
    expect(rows[0]).toEqual({ users: 1, steps: 1, training_exercises: 1, completions: 1, models: 1 });

    const state = await pool.query(`SELECT is_favorite, updated_at FROM user_exercise_states WHERE user_id = 'u1'`);
    expect(state.rows[0]).toEqual({ is_favorite: true, updated_at: COMPLETED });
  });

  it('no escribe sobre una base con datos, salvo con replace', async () => {
    await seedFirestore();
    const plan = await planFromFirestore();
    await loadRows(pool, plan.rows, { replace: false });

    await expect(loadRows(pool, plan.rows, { replace: false })).rejects.toThrow('already has data');
    await expect(loadRows(pool, plan.rows, { replace: true })).resolves.toBeUndefined();

    const { rows } = await pool.query('SELECT count(*)::int AS total FROM users');
    expect(rows[0].total).toBe(1);
  });

  it('insertMissingUsers añade los perfiles que faltan y no pisa los que hay', async () => {
    await seedFirestore();
    await loadRows(pool, (await planFromFirestore()).rows, { replace: false });
    await pool.query(`UPDATE users SET display_name = 'Editado' WHERE id = 'u1'`);
    await db.collection('users').doc('u2').set({ email: 'ben@test.dev' });

    const inserted = await insertMissingUsers(pool, (await planFromFirestore()).rows);

    expect(inserted).toBe(1);
    const { rows } = await pool.query('SELECT id, display_name FROM users ORDER BY id');
    expect(rows).toEqual([
      { id: 'u1', display_name: 'Editado' },
      { id: 'u2', display_name: null },
    ]);
  });
});
