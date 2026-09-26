import { Request, Response } from 'express';
import AuthController from '../../../src/controllers/AuthController';
import { HttpError } from '../../../src/utils/httpError';

// Se mockea el container entero: AuthService habla con Firebase y UserService
// con Postgres, y aquí solo importa qué hace el controller con sus errores.
const mockSignUp = jest.fn();
const mockCreateUser = jest.fn();
jest.mock('../../../src/container', () => ({
  services: {
    auth: { signUp: (...args: unknown[]) => mockSignUp(...args) },
    users: { create: (...args: unknown[]) => mockCreateUser(...args) },
  },
}));

const req = { body: { email: 'ana@test.dev', password: 'Abc12345', displayName: 'Ana' } } as Request;
const res = { status: jest.fn(() => ({ json: jest.fn() })) } as unknown as Response;

describe('AuthController.signUp', () => {
  beforeEach(() => jest.clearAllMocks());

  it('un error de cuenta de Firebase se convierte en 400 con su mensaje', async () => {
    mockSignUp.mockRejectedValue({ code: 'auth/email-already-exists', message: 'The email address is already in use' });
    const next = jest.fn();

    await AuthController.signUp(req, res, next);

    const passed = next.mock.calls[0][0];
    expect(passed).toBeInstanceOf(HttpError);
    expect(passed).toMatchObject({ status: 400, message: 'The email address is already in use' });
  });

  it('cualquier otro error pasa tal cual a errorHandler (que responde 500 genérico)', async () => {
    mockSignUp.mockResolvedValue({ uid: 'u1', email: 'ana@test.dev' });
    const dbError = new Error('connection terminated unexpectedly');
    mockCreateUser.mockRejectedValue(dbError);
    const next = jest.fn();

    await AuthController.signUp(req, res, next);

    expect(next).toHaveBeenCalledWith(dbError);
  });
});
