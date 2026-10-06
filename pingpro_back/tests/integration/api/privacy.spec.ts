import request from 'supertest';
import app from '../../../src/app';
import { closeDatabase } from '../../../src/container';
import { closeFirebaseApp } from '../helpers/emulators';

// Importar app arranca firebase-admin y el pool de Postgres: hay que cerrarlos
// para que jest termine.
afterAll(async () => {
  await closeDatabase();
  await closeFirebaseApp();
});

describe('GET /privacy', () => {
  const previous = process.env.SUPPORT_EMAIL;
  afterEach(() => {
    if (previous === undefined) delete process.env.SUPPORT_EMAIL;
    else process.env.SUPPORT_EMAIL = previous;
  });

  it('responde HTML sin pedir token e incluye el correo de soporte', async () => {
    process.env.SUPPORT_EMAIL = 'pingproteam@gmail.com';

    const res = await request(app).get('/privacy');

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/text\/html/);
    expect(res.text).toContain('mailto:pingproteam@gmail.com');
  });
});
