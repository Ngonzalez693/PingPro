import { poolConfig } from '../../../src/config/postgres';

const LOCAL_TEST = 'postgres://pingpro_test:pingpro_test@127.0.0.1:5433/pingpro_test';
const REMOTE = 'postgres://postgres.ref:secret@aws-0-sa-east-1.pooler.supabase.com:5432/postgres';

// poolConfig es pura: se prueba sin conectar a ninguna base de datos.
describe('poolConfig', () => {
  it('sin DATABASE_URL falla con un mensaje claro', () => {
    expect(() => poolConfig(undefined, 'development')).toThrow('DATABASE_URL is not set');
  });

  it('en local no usa SSL', () => {
    expect(poolConfig(LOCAL_TEST, 'test').ssl).toBe(false);
  });

  it('fuera de local verifica el certificado con la CA de Supabase', () => {
    expect(poolConfig(REMOTE, 'production').ssl).toEqual({
      ca: expect.stringContaining('-----BEGIN CERTIFICATE-----'),
      rejectUnauthorized: true,
    });
  });

  it('rechaza una URL con sslmode: pisaría la verificación con la CA', () => {
    expect(() => poolConfig(`${REMOTE}?sslmode=require`, 'production')).toThrow('Remove sslmode');
  });

  it('en tests rechaza una base remota', () => {
    expect(() => poolConfig(REMOTE, 'test')).toThrow('local *_test database');
  });

  it('en tests rechaza una base local que no es de test', () => {
    expect(() => poolConfig('postgres://u:p@127.0.0.1:5433/pingpro_dev', 'test')).toThrow(
      'local *_test database',
    );
  });
});
