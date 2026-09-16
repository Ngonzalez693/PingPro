import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

const PASSWORD = 'Abc12345';

function signup(email: string) {
  return request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Test User' });
}

// Registro de punta a punta sobre la app real: Auth sigue siendo Firebase
// (emulador) y el perfil ya vive en Postgres. Hace 4 registros: muy por debajo
// del rate limit (20 cada 15 min).
describe('Auth API (emulador de Auth + Postgres)', () => {
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

  it('signup crea la cuenta y el perfil con rol user', async () => {
    const res = await signup('ana@test.dev');

    expect(res.status).toBe(201);
    const { rows } = await pool.query('SELECT roles FROM users WHERE id = $1', [res.body.data.uid]);
    expect(rows).toEqual([{ roles: ['user'] }]);
  });

  it('verify acepta un token real del emulador y devuelve el mismo uid', async () => {
    const created = await signup('ben@test.dev');
    const idToken = await signInWithEmulator('ben@test.dev', PASSWORD);

    const res = await request(app)
      .post('/api/auth/verify')
      .set('Authorization', `Bearer ${idToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.uid).toBe(created.body.data.uid);
  });

  it('verify rechaza con 401 un token inválido', async () => {
    const res = await request(app)
      .post('/api/auth/verify')
      .set('Authorization', 'Bearer garbage');

    expect(res.status).toBe(401);
  });

  it('un email repetido devuelve 400 con "already in use", del que depende la app', async () => {
    await signup('cris@test.dev');

    const res = await signup('cris@test.dev');

    // auth_service.dart busca este texto para intentar el login en vez del
    // registro. Si cambia, la app se rompe.
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('already in use');
  });
});
