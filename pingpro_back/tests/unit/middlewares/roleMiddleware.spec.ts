import { Request, Response, NextFunction } from 'express';
import { requireRole, requireSelfOrRole } from '@middlewares/roleMiddleware';

// Se mockea UserService para no tocar Firestore: lo que se prueba es la
// decisión de autorización, no la lectura del documento.
//
// El nombre tiene que empezar por "mock" para que jest permita referenciarlo
// dentro de la factory, que se hoistea por encima de los imports.
//
// La llamada va envuelta en una lambda a propósito: roleMiddleware instancia
// UserService al importarse, antes de que esta constante exista. Referenciarla
// directamente daría "Cannot access before initialization".
const mockGetById = jest.fn();
jest.mock('@services/UserService', () => ({
  UserService: jest.fn().mockImplementation(() => ({
    getById: (...args: unknown[]) => mockGetById(...args),
  })),
}));

const getByIdMock = mockGetById;

/** Response mínimo que registra el status y el cuerpo enviados. */
function mockRes() {
  const res: Partial<Response> & { statusCode?: number; body?: unknown } = {};
  res.status = jest.fn().mockImplementation((code: number) => {
    res.statusCode = code;
    return res as Response;
  });
  res.json = jest.fn().mockImplementation((payload: unknown) => {
    res.body = payload;
    return res as Response;
  });
  return res as Response & { statusCode?: number; body?: any };
}

function mockReq(uid?: string, paramId?: string) {
  return {
    user: uid ? { uid } : undefined,
    params: paramId ? { id: paramId } : {},
  } as unknown as Request;
}

describe('requireRole', () => {
  beforeEach(() => jest.clearAllMocks());

  it('deja pasar a un usuario con el rol pedido', async () => {
    getByIdMock.mockResolvedValue({ id: 'u1', email: 'a@b.c', roles: ['admin'] });
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireRole('admin')(mockReq('u1'), res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('devuelve 403 a un usuario normal', async () => {
    getByIdMock.mockResolvedValue({ id: 'u2', email: 'a@b.c', roles: ['user'] });
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireRole('admin')(mockReq('u2'), res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
  });

  it('devuelve 403 si el perfil no tiene roles', async () => {
    getByIdMock.mockResolvedValue({ id: 'u3', email: 'a@b.c' });
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireRole('admin')(mockReq('u3'), res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
  });

  it('devuelve 403 si el perfil no existe (getById lanza 404)', async () => {
    getByIdMock.mockRejectedValue(Object.assign(new Error('User not found'), { status: 404 }));
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireRole('admin')(mockReq('fantasma'), res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
  });

  it('devuelve 401 si no hay uid en la petición', async () => {
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireRole('admin')(mockReq(), res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(401);
    expect(getByIdMock).not.toHaveBeenCalled();
  });
});

describe('requireSelfOrRole', () => {
  beforeEach(() => jest.clearAllMocks());

  it('deja pasar al dueño del recurso sin consultar sus roles', async () => {
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireSelfOrRole('admin')(mockReq('u1', 'u1'), res, next);

    expect(next).toHaveBeenCalled();
    // Atajo importante: ser el dueño evita la lectura extra a Firestore.
    expect(getByIdMock).not.toHaveBeenCalled();
  });

  it('bloquea con 403 a un usuario que apunta a la cuenta de otro', async () => {
    getByIdMock.mockResolvedValue({ id: 'u1', email: 'a@b.c', roles: ['user'] });
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireSelfOrRole('admin')(mockReq('u1', 'u2'), res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
  });

  it('deja pasar al admin sobre la cuenta de otro', async () => {
    getByIdMock.mockResolvedValue({ id: 'jefe', email: 'a@b.c', roles: ['admin'] });
    const next = jest.fn() as NextFunction;
    const res = mockRes();

    await requireSelfOrRole('admin')(mockReq('jefe', 'u2'), res, next);

    expect(next).toHaveBeenCalled();
  });
});
