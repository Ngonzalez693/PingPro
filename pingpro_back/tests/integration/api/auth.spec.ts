import request from 'supertest';
import app from '../../../src/app';


describe('Auth API (integración)', () => {
  it('signup y verifyToken', async () => {
    const email = `test${Date.now()}@mail.com`;
    const signup = await request(app)
      .post('/auth/signup')
      .send({ email, password: 'Abc12345', displayName: 'TestUser' });
    expect(signup.status).toBe(201);
    const { uid } = signup.body.data;

    const verify = await request(app)
      .post('/auth/verify')
      .set('Authorization', `Bearer ${signup.body.data.uid}`);
    expect(verify.status).toBe(200);
    expect(verify.body.data.uid).toBe(uid);
  });
});