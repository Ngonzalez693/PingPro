import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

const PASSWORD = 'Abc12345';

// Registra un usuario por la API (crea la cuenta y su fila en users) y
// devuelve su uid y un token real del emulador.
async function registerUser(email: string): Promise<{ uid: string; token: string }> {
  const res = await request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Test User' });
  if (res.status !== 201) {
    throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
  }
  const token = await signInWithEmulator(email, PASSWORD);
  return { uid: res.body.data.uid, token };
}

function updateProfile(uid: string, token: string | null, body: object) {
  const req = request(app).put(`/api/users/${uid}`).send(body);
  return token ? req.set('Authorization', `Bearer ${token}`) : req;
}

// Es el endpoint con el que la app guarda el perfil. Hace 7 registros: por
// debajo del rate limit (20 cada 15 min).
describe('PUT /api/users/:id (emulador de Auth + Postgres)', () => {
  const pool: Pool = createPool();

  beforeAll(() => migrate(pool));
  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
  });
  afterAll(async () => {
    await pool.end();
    await closeDatabase();
    await closeFirebaseApp();
  });

  it('actualiza el nombre del propio perfil', async () => {
    const { uid, token } = await registerUser('ana@test.dev');

    const res = await updateProfile(uid, token, { displayName: 'Ana García' });

    expect(res.status).toBe(200);
    const me = await request(app).get('/api/users/me').set('Authorization', `Bearer ${token}`);
    expect(me.status).toBe(200);
    expect(me.body.data.displayName).toBe('Ana García');
    expect(me.body.data.updatedAt).toEqual(expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/));
  });

  it('no deja que un usuario se asigne roles (400) y sus roles no cambian', async () => {
    const { uid, token } = await registerUser('ben@test.dev');

    const res = await updateProfile(uid, token, { roles: ['admin'] });

    expect(res.status).toBe(400);
    const { rows } = await pool.query('SELECT roles FROM users WHERE id = $1', [uid]);
    expect(rows[0].roles).toEqual(['user']);
  });

  it('no deja editar el perfil de otro usuario (403)', async () => {
    const owner = await registerUser('cris@test.dev');
    const other = await registerUser('dani@test.dev');

    const res = await updateProfile(owner.uid, other.token, { displayName: 'Otro' });

    expect(res.status).toBe(403);
  });

  it('rechaza un cuerpo vacío (400)', async () => {
    const { uid, token } = await registerUser('eva@test.dev');

    const res = await updateProfile(uid, token, {});

    expect(res.status).toBe(400);
  });

  it('exige token (401)', async () => {
    const { uid } = await registerUser('fer@test.dev');

    const res = await updateProfile(uid, null, { displayName: 'Fer' });

    expect(res.status).toBe(401);
  });

  it('responde 404 si el perfil no existe', async () => {
    const { uid, token } = await registerUser('gabi@test.dev');
    await pool.query('DELETE FROM users WHERE id = $1', [uid]);

    const res = await updateProfile(uid, token, { displayName: 'Gabi' });

    expect(res.status).toBe(404);
  });
});
