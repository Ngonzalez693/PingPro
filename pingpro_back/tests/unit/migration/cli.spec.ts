import { parseArgs } from '../../../src/migration/cli';

describe('parseArgs', () => {
  it('sin argumentos, todo desactivado: solo simula', () => {
    expect(parseArgs([])).toEqual({ apply: false, replace: false, missingUsersOnly: false });
  });

  it('--apply activa la carga', () => {
    expect(parseArgs(['--apply'])).toMatchObject({ apply: true, replace: false });
  });

  it('--apply --replace permite cargar sobre una base con datos', () => {
    expect(parseArgs(['--apply', '--replace'])).toMatchObject({ apply: true, replace: true });
  });

  it('una opción desconocida falla y lista las válidas', () => {
    expect(() => parseArgs(['--force'])).toThrow('Unknown option --force');
  });
});
