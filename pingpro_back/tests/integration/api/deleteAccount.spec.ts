import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { auth } from '../../../src/config/firebase';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres, seedExercises } from '../helpers/postgres';

const PASSWORD = 'Abc12345';
const CATALOG_ID = 'cat1';

const exercise = {
  name: 'Topspin cruzado',
  category: 'Técnico',
  image: 'assets/images/exercise_1.jpg',
  sequence: [{ hit: 1, rotation: 2, zone: 3, direction: 6, side: 1 }],
};

interface TestUser {
  uid: string;
  token: string;
}

// Registra un usuario por la API (cuenta de Auth + fila en users) y devuelve
// su uid y un token real del emulador.
async function registerUser(email: string): Promise<TestUser> {
  const res = await request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Test User' });
  if (res.status !== 201) {
    throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
  }
  const token = await signInWithEmulator(email, PASSWORD);
  return { uid: res.body.data.uid, token };
}

function deleteMe(token?: string) {
  const req = request(app).delete('/api/users/me');
  return token ? req.set('Authorization', `Bearer ${token}`) : req;
}

// Un poco de cada tabla que cuelga del usuario: ejercicio y entrenamiento
// propios, ambos completados, y el ejercicio de catálogo marcado favorito.
async function seedOwnData(token: string): Promise<void> {
  const authed = (req: request.Test) => req.set('Authorization', `Bearer ${token}`);
  const created = await authed(request(app).post('/api/exercises/me')).send(exercise);
  expect(created.status).toBe(201);
  const exerciseId = created.body.data.id;
  const training = await authed(request(app).post('/api/trainings/me')).send({
    name: 'Calentamiento',
    category: 'Grado',
    image: 'assets/images/training_1.jpg',
    exerciseIds: [exerciseId],
    duration: 20,
  });
  expect(training.status).toBe(201);
  const responses = [
    await authed(request(app).post(`/api/exercises/${exerciseId}/completed`)).send({ session: 1 }),
    await authed(request(app).post(`/api/trainings/${training.body.data.id}/completed`)).send({ session: 1 }),
    await authed(request(app).post(`/api/exercises/${CATALOG_ID}/favorite`)).send({ isFavorite: true }),
  ];
  responses.forEach((res) => expect(res.status).toBe(200));
}

// Cuántas filas apuntan todavía al usuario, tabla por tabla.
async function rowsOf(pool: Pool, uid: string): Promise<Record<string, number>> {
  const { rows } = await pool.query(
    `SELECT
       (SELECT count(*) FROM users WHERE id = $1)::int AS users,
       (SELECT count(*) FROM exercises WHERE owner_id = $1)::int AS exercises,
       (SELECT count(*) FROM trainings WHERE owner_id = $1)::int AS trainings,
       (SELECT count(*) FROM user_exercise_states WHERE user_id = $1)::int AS exercise_states,
       (SELECT count(*) FROM exercise_completions WHERE user_id = $1)::int AS exercise_completions,
       (SELECT count(*) FROM user_training_states WHERE user_id = $1)::int AS training_states,
       (SELECT count(*) FROM training_completions WHERE user_id = $1)::int AS training_completions`,
    [uid],
  );
  return rows[0];
}

const NOTHING_LEFT = {
  users: 0,
  exercises: 0,
  trainings: 0,
  exercise_states: 0,
  exercise_completions: 0,
  training_states: 0,
  training_completions: 0,
};

// Cuatro registros como mucho: por debajo del rate limit (20 cada 15 min).
describe('DELETE /api/users/me (emulador de Auth + Postgres)', () => {
  const pool: Pool = createPool();

  beforeAll(() => migrate(pool));
  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
    await seedExercises(pool, [CATALOG_ID]);
  });
  afterAll(async () => {
    await pool.end();
    await closeDatabase();
    await closeFirebaseApp();
  });

  it('borra el perfil, sus datos privados y la cuenta de Auth', async () => {
    const ana = await registerUser('ana@test.dev');
    await seedOwnData(ana.token);
    const before = await rowsOf(pool, ana.uid);
    expect(before).toMatchObject({ users: 1, exercises: 1, trainings: 1, exercise_completions: 1, training_completions: 1 });
    expect(before.exercise_states).toBeGreaterThan(0);

    const res = await deleteMe(ana.token);

    expect(res.status).toBe(200);
    expect(await rowsOf(pool, ana.uid)).toEqual(NOTHING_LEFT);
    await expect(auth.getUser(ana.uid)).rejects.toMatchObject({ code: 'auth/user-not-found' });
  });

  it('no toca el catálogo ni los datos de otro usuario', async () => {
    const ana = await registerUser('ana@test.dev');
    const ben = await registerUser('ben@test.dev');
    await seedOwnData(ana.token);
    await seedOwnData(ben.token);
    const benBefore = await rowsOf(pool, ben.uid);

    const res = await deleteMe(ana.token);

    expect(res.status).toBe(200);
    expect(await rowsOf(pool, ben.uid)).toEqual(benBefore);
    const catalog = await pool.query('SELECT 1 FROM exercises WHERE id = $1', [CATALOG_ID]);
    expect(catalog.rowCount).toBe(1);
    await expect(auth.getUser(ben.uid)).resolves.toMatchObject({ uid: ben.uid });
  });

  // Un token de una cuenta ya borrada lo rechaza authMiddleware, así que el
  // cliente solo puede reintentar mientras la cuenta de Auth todavía existe:
  // por eso se simula el borrado a medias (fila borrada, Auth intacto).
  it('tras un borrado a medias (sin fila, con cuenta de Auth) termina de borrar', async () => {
    const ana = await registerUser('ana@test.dev');
    await pool.query('DELETE FROM users WHERE id = $1', [ana.uid]);

    const res = await deleteMe(ana.token);

    expect(res.status).toBe(200);
    expect(await rowsOf(pool, ana.uid)).toEqual(NOTHING_LEFT);
    await expect(auth.getUser(ana.uid)).rejects.toMatchObject({ code: 'auth/user-not-found' });
  });

  it('sin token responde 401', async () => {
    const res = await deleteMe();

    expect(res.status).toBe(401);
  });
});
