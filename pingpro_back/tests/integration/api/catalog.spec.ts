import request from 'supertest';
import app from '../../../src/app';
import { db } from '../../../src/config/firebase';
import { clearAuth, clearFirestore, closeFirebaseApp, signInWithEmulator } from '../helpers/emulators';

const PASSWORD = 'Abc12345';

// Registra un usuario por la API, le da el rol admin en su perfil (de ahí lo
// lee requireRole) y devuelve un token real del emulador.
async function registerAdmin(email: string): Promise<string> {
  const res = await request(app)
    .post('/api/auth/signup')
    .send({ email, password: PASSWORD, displayName: 'Admin' });
  if (res.status !== 201) {
    throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
  }
  await db.collection('users').doc(res.body.data.uid).update({ roles: ['admin'] });
  return signInWithEmulator(email, PASSWORD);
}

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
// controlador, servicio y Firestore. Hace 3 registros, por debajo del rate
// limit (20 cada 15 min).
describe('Escrituras del catálogo (emuladores)', () => {
  let token: string;

  beforeEach(async () => {
    await Promise.all([clearAuth(), clearFirestore()]);
    token = await registerAdmin('admin@test.dev');
  });
  afterAll(closeFirebaseApp);

  function post(path: string, body: object) {
    return request(app).post(path).set('Authorization', `Bearer ${token}`).send(body);
  }

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
    const saved = await db.collection('trainings').get();
    expect(saved.empty).toBe(true);
  });

  it('crea un entrenamiento con un ejercicio que existe (201)', async () => {
    const created = await post('/api/exercises', exercise);
    expect(created.status).toBe(201);

    const res = await post('/api/trainings', { ...training, exerciseIds: [created.body.data.id] });

    expect(res.status).toBe(201);
  });
});
