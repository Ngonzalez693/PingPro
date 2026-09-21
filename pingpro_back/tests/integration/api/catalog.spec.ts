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

// El pool, la migración y el cierre son del archivo entero, no de cada
// describe: closeFirebaseApp() y closeDatabase() cierran recursos compartidos,
// y en un afterAll por bloque el primero en terminar dejaba al siguiente sin
// app de Firebase.
const pool: Pool = createPool();

beforeAll(() => migrate(pool));
afterAll(async () => {
  await pool.end();
  await closeDatabase();
  await closeFirebaseApp();
});

// Escrituras del catálogo por la cadena completa: ruta, requireRole, Joi,
// controlador, servicio y Postgres. Cada prueba hace un registro, por debajo
// del rate limit (20 cada 15 min).
describe('Escrituras del catálogo (emulador de Auth + Postgres)', () => {
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

  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
    token = await registerAdmin('admin@test.dev');
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

// Ejercicios y entrenamientos propios por la cadena completa. Aquí el usuario
// NO es admin: es el caso normal de alguien creando lo suyo.
//
// El "otro usuario" se inserta por SQL en vez de registrarlo: solo hace falta
// que exista para la clave foránea de owner_id, y así cada prueba gasta un
// único registro del rate limit de signup.
describe('Escrituras propias (emulador de Auth + Postgres)', () => {
  let token: string;
  let uid: string;

  async function registerUser(email: string): Promise<{ uid: string; token: string }> {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email, password: PASSWORD, displayName: 'Jugador' });
    if (res.status !== 201) {
      throw new Error(`signup failed: ${res.status} ${JSON.stringify(res.body)}`);
    }
    return { uid: res.body.data.uid, token: await signInWithEmulator(email, PASSWORD) };
  }

  async function insertUser(id: string): Promise<void> {
    await pool.query('INSERT INTO users (id, email) VALUES ($1, $2)', [id, `${id}@test.dev`]);
  }

  async function insertExercise(ownerId: string | null): Promise<string> {
    const { rows } = await pool.query<{ id: string }>(
      `INSERT INTO exercises (owner_id, name, category, image)
       VALUES ($1, 'Ajeno', 'Técnico', 'assets/images/exercise_1.jpg')
       RETURNING id`,
      [ownerId],
    );
    return rows[0].id;
  }

  const auth = (req: request.Test) => req.set('Authorization', `Bearer ${token}`);

  beforeEach(async () => {
    await clearAuth();
    await resetPostgres(pool);
    ({ uid, token } = await registerUser('jugador@test.dev'));
  });

  it('un usuario normal crea un ejercicio suyo (201) y queda a su nombre', async () => {
    const res = await auth(request(app).post('/api/exercises/me')).send(exercise);

    expect(res.status).toBe(201);
    const { rows } = await pool.query('SELECT owner_id FROM exercises WHERE id = $1', [res.body.data.id]);
    expect(rows[0].owner_id).toBe(uid);
  });

  it('un usuario normal no puede escribir en el catálogo (403)', async () => {
    const res = await auth(request(app).post('/api/exercises')).send(exercise);

    expect(res.status).toBe(403);
  });

  it('el ownerId del body se rechaza: el dueño sale del token', async () => {
    await insertUser('otro');

    const res = await auth(request(app).post('/api/exercises/me')).send({ ...exercise, ownerId: 'otro' });

    expect(res.status).toBe(400);
  });

  it('el listado trae el catálogo y lo propio, nunca lo de otro', async () => {
    await insertUser('otro');
    await insertExercise(null);    // catálogo
    await insertExercise('otro');  // privado ajeno
    await auth(request(app).post('/api/exercises/me')).send(exercise);

    const res = await auth(request(app).get('/api/exercises'));

    expect(res.status).toBe(200);
    expect(res.body.data.map((e: { name: string }) => e.name).sort()).toEqual(['Ajeno', exercise.name].sort());
  });

  it('no se puede editar el ejercicio privado de otro (404) y no cambia', async () => {
    await insertUser('otro');
    const ajeno = await insertExercise('otro');

    const res = await auth(request(app).put(`/api/exercises/me/${ajeno}`)).send({ ...exercise, name: 'Pisado' });

    expect(res.status).toBe(404);
    const { rows } = await pool.query('SELECT name FROM exercises WHERE id = $1', [ajeno]);
    expect(rows[0].name).toBe('Ajeno');
  });

  it('no se puede borrar un ejercicio del catálogo por la ruta propia (404)', async () => {
    const delCatalogo = await insertExercise(null);

    const res = await auth(request(app).delete(`/api/exercises/me/${delCatalogo}`));

    expect(res.status).toBe(404);
    const { rows } = await pool.query('SELECT deleted_at FROM exercises WHERE id = $1', [delCatalogo]);
    expect(rows[0].deleted_at).toBeNull();
  });

  it('un entrenamiento propio mezcla ejercicios del catálogo y propios', async () => {
    const delCatalogo = await insertExercise(null);
    const mio = await auth(request(app).post('/api/exercises/me')).send(exercise);

    const res = await auth(request(app).post('/api/trainings/me')).send({
      ...training,
      exerciseIds: [delCatalogo, mio.body.data.id],
    });

    expect(res.status).toBe(201);
  });

  it('un entrenamiento propio no puede usar el ejercicio privado de otro (400)', async () => {
    await insertUser('otro');
    const ajeno = await insertExercise('otro');

    const res = await auth(request(app).post('/api/trainings/me')).send({
      ...training,
      exerciseIds: [ajeno],
    });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe(`Unknown exercise ids: ${ajeno}`);
  });
});
