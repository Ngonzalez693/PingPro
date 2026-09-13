import request from 'supertest';
import app from '../../../src/app';
import { db } from '../../../src/config/firebase';
import { clearAuth, clearFirestore, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';

const PASSWORD = 'Abc12345';

function signup(email: string) {
  return request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Test User' });
}

// Registro de punta a punta sobre la app real y los emuladores de Auth y
// Firestore. Hace 4 registros: muy por debajo del rate limit (20 cada 15 min).
describe('Auth API (emuladores)', () => {
  beforeEach(async () => {
    await Promise.all([clearAuth(), clearFirestore()]);
  });
  afterAll(closeFirebaseApp);

  it('signup crea la cuenta y el perfil users/{uid} con rol user', async () => {
    const res = await signup('ana@test.dev');

    expect(res.status).toBe(201);
    const profile = await db.collection('users').doc(res.body.data.uid).get();
    expect(profile.exists).toBe(true);
    expect(profile.data()?.roles).toEqual(['user']);
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
    // registro. Si cambia (por ejemplo al pasar a Supabase), la app se rompe.
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('already in use');
  });
});
