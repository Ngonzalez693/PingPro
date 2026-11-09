import request from 'supertest';
import type { Pool } from 'pg';
import app from '../../../src/app';
import { createPool } from '../../../src/config/postgres';
import { closeDatabase } from '../../../src/container';
import { migrate } from '../../../src/db/migrate';
import { clearAuth, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';
import { resetPostgres } from '../helpers/postgres';

const PASSWORD = 'Abc12345';
const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

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

function putPhoto(token: string | null, body: Buffer | string, type = 'image/png') {
  const req = request(app).put('/api/users/me/photo').set('Content-Type', type).send(body);
  return token ? req.set('Authorization', `Bearer ${token}`) : req;
}

// Sin las variables de Supabase (como en los tests), subir responde 503: así
// se comprueba todo el camino hasta el almacenamiento sin tocar el bucket.
// Un solo registro para toda la suite: muy por debajo del rate limit.
describe('Foto de perfil (emulador de Auth + Postgres, sin Supabase)', () => {
  const pool: Pool = createPool();
  let user: { uid: string; token: string };

  beforeAll(async () => {
    await migrate(pool);
    await clearAuth();
    await resetPostgres(pool);
    user = await registerUser('foto@test.dev');
  });
  afterAll(async () => {
    await pool.end();
    await closeDatabase();
    await closeFirebaseApp();
  });

  it('exige token (401)', async () => {
    const res = await putPhoto(null, Buffer.from(PNG_SIGNATURE));

    expect(res.status).toBe(401);
  });

  it('rechaza un cuerpo que no es una imagen PNG (400)', async () => {
    const res = await putPhoto(user.token, 'hola', 'text/plain');

    expect(res.status).toBe(400);
  });

  it('rechaza un JPEG enviado como PNG (400)', async () => {
    const res = await putPhoto(user.token, Buffer.from([0xff, 0xd8, 0xff, 0xe0]));

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('La foto tiene que ser una imagen PNG');
  });

  it('rechaza una foto de más de 2 MB (413) con un mensaje en español', async () => {
    const big = Buffer.alloc(2 * 1024 * 1024 + 1);
    Buffer.from(PNG_SIGNATURE).copy(big);

    const res = await putPhoto(user.token, big);

    expect(res.status).toBe(413);
    expect(res.body.message).toBe('La foto pesa demasiado (máximo 2 MB)');
  });

  it('con un PNG válido llega al almacenamiento (503 sin Supabase)', async () => {
    const res = await putPhoto(user.token, Buffer.from([...PNG_SIGNATURE, 1, 2, 3]));

    expect(res.status).toBe(503);
  });

  it('quitar la foto sin tener una responde 200', async () => {
    const res = await request(app).delete('/api/users/me/photo').set('Authorization', `Bearer ${user.token}`);

    expect(res.status).toBe(200);
  });

  it('PUT /api/users/:id ya no acepta photoURL (400)', async () => {
    const res = await request(app)
      .put(`/api/users/${user.uid}`)
      .set('Authorization', `Bearer ${user.token}`)
      .send({ photoURL: 'https://x/y.png' });

    expect(res.status).toBe(400);
  });
});
