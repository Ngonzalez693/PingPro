import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

const PASSWORD = 'Abc12345';

const exercise = {
  name: 'Topspin cruzado',
  category: 'Técnico',
  image: 'assets/images/exercise_1.jpg',
  sequence: [{ hit: 1, rotation: 2, zone: 3, direction: 6, side: 1 }],
};

const training = {
  name: 'Calentamiento',
  category: 'Grado',
  image: 'assets/images/training_1.jpg',
  duration: 20,
};

// Escrituras del catálogo por la cadena completa: ruta, requireRole, Joi,
// controlador, servicio y Postgres. Hace 3 registros, por debajo del rate
// limit (20 cada 15 min).
describe('Escrituras del catálogo (emulador de Auth + Postgres)', () => {
  const pool: Pool = createPool();
  let token: string;

  // Registra un usuario por la API, le da el rol admin en su fila (de ahí lo
  // lee requireRole) y devuelve un token real del emulador.
  async function registerAdmin(email: string): Promise<string> {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email, password: PASSWORD, displayName: 'Admin' });
    if (res.status !== 201) {
      throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
    }
    await pool.query('UPDATE users SET roles = $2 WHERE id = $1', [res.body.data.uid, ['admin']]);
    return signInWithEmulator(email, PASSWORD);
  }

  function post(path: string, body: object) {
    return request(app).post(path).set('Authorization', `Bearer ${token}`).send(body);
  }

  beforeAll(() => migrate(pool));
  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
    token = await registerAdmin('admin@test.dev');
  });
  afterAll(async () => {
    await pool.end();
    await closeDatabase();
    await closeFirebaseApp();
  });

  it('rechaza un ejercicio con un código de golpe fuera del enum (400)', async () => {
    const res = await post('/api/exercises', {
      ...exercise,
      sequence: [{ ...exercise.sequence[0], hit: 10 }],
    });

    expect(res.status).toBe(400);
  });

  it('rechaza un entrenamiento con ejercicios inexistentes (400) y no lo guarda', async () => {
    const res = await post('/api/trainings', { ...training, exerciseIds: ['no-existe'] });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Unknown exercise ids: no-existe');
    const { rows } = await pool.query('SELECT count(*)::int AS total FROM trainings');
    expect(rows[0].total).toBe(0);
  });

  it('crea un entrenamiento con un ejercicio que existe (201)', async () => {
    const created = await post('/api/exercises', exercise);
    expect(created.status).toBe(201);

    const res = await post('/api/trainings', { ...training, exerciseIds: [created.body.data.id] });

    expect(res.status).toBe(201);
  });
});
