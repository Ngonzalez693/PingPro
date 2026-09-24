import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

const PASSWORD = 'Abc12345';
const DAY_MS = 24 * 60 * 60 * 1000;

const exercise = {
  name: 'Topspin cruzado',
  category: 'Técnico',
  image: 'assets/images/exercise_1.jpg',
  sequence: [{ hit: 1, rotation: 2, zone: 3, direction: 6, side: 1 }],
};

const pool: Pool = createPool();

beforeAll(() => migrate(pool));
afterAll(async () => {
  await pool.end();
  await closeDatabase();
  await closeFirebaseApp();
});

// Registra un usuario por la API y devuelve un token real del emulador.
async function registerUser(email: string): Promise<string> {
  const res = await request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Test User' });
  if (res.status !== 201) {
    throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
  }
  return signInWithEmulator(email, PASSWORD);
}

function yesterday(): string {
  return new Date(Date.now() - DAY_MS).toISOString();
}

// La cadena completa: ruta, authMiddleware, Joi, controlador, servicio y
// Postgres. Cinco registros, por debajo del rate limit (20 cada 15 min).
describe('Estadísticas por HTTP (emulador de Auth + Postgres)', () => {
  let token: string;

  function authed(req: request.Test): request.Test {
    return req.set('Authorization', `Bearer ${token}`);
  }

  async function createOwnExercise(): Promise<string> {
    const res = await authed(request(app).post('/api/exercises/me')).send(exercise);
    expect(res.status).toBe(201);
    return res.body.data.id;
  }

  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
    token = await registerUser('ana@test.dev');
  });

  it('sin token responde 401', async () => {
    const res = await request(app).get('/api/stats/me/events').query({ from: yesterday() });

    expect(res.status).toBe(401);
  });

  it('sin from responde 400', async () => {
    const res = await authed(request(app).get('/api/stats/me/events'));

    expect(res.status).toBe(400);
  });

  it('una finalización con sesión y lo creado llegan como eventos', async () => {
    const id = await createOwnExercise();
    const done = await authed(request(app).post(`/api/exercises/${id}/completed`)).send({ session: 2 });
    expect(done.status).toBe(200);

    const res = await authed(request(app).get('/api/stats/me/events')).query({ from: yesterday() });

    expect(res.status).toBe(200);
    expect(res.body.data.exerciseCompletions).toEqual([
      {
        exerciseId: id,
        completedAt: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
        session: 2,
        category: 'Técnico',
        hits: [1],
        rotations: [2],
        deleted: false,
      },
    ]);
    expect(res.body.data.created).toEqual([
      { kind: 'exercise', id, createdAt: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/) },
    ]);
  });

  it('un entrenamiento rechaza una sesión fuera de 1..3 y guarda una válida', async () => {
    const exerciseId = await createOwnExercise();
    const created = await authed(request(app).post('/api/trainings/me')).send({
      name: 'Calentamiento',
      category: 'Grado',
      image: 'assets/images/training_1.jpg',
      exerciseIds: [exerciseId],
      duration: 20,
    });
    expect(created.status).toBe(201);
    const trainingId = created.body.data.id;

    const rejected = await authed(request(app).post(`/api/trainings/${trainingId}/completed`)).send({ session: 4 });
    const accepted = await authed(request(app).post(`/api/trainings/${trainingId}/completed`)).send({ session: 1 });
    const res = await authed(request(app).get('/api/stats/me/events')).query({ from: yesterday() });

    expect(rejected.status).toBe(400);
    expect(accepted.status).toBe(200);
    expect(res.body.data.trainingCompletions).toEqual([
      { trainingId, completedAt: expect.any(String), session: 1, duration: 20 },
    ]);
  });

  it('la app vieja (sin sesión) sigue completando', async () => {
    const id = await createOwnExercise();

    const done = await authed(request(app).post(`/api/exercises/${id}/completed`)).send({ completed: true });
    const res = await authed(request(app).get('/api/stats/me/events')).query({ from: yesterday() });

    expect(done.status).toBe(200);
    expect(res.body.data.exerciseCompletions[0].session).toBeNull();
  });
});
