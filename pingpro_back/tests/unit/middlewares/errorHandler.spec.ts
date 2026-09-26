import { Request, Response } from 'express';
import errorHandler from '../../../src/middlewares/errorHandler';
import { HttpError } from '../../../src/utils/httpError';
import logger from '../../../src/utils/logger';

jest.mock('../../../src/utils/logger', () => ({
  __esModule: true,
  default: { error: jest.fn() },
}));

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
  return res;
}

function handle(err: unknown) {
  const res = mockRes();
  errorHandler(err, {} as Request, res as Response, jest.fn());
  return res;
}

describe('errorHandler', () => {
  beforeEach(() => jest.clearAllMocks());

  it('un HttpError responde con su status y su mensaje', () => {
    const res = handle(new HttpError(404, 'Training not found'));

    expect(res.statusCode).toBe(404);
    expect(res.body).toEqual({ success: false, message: 'Training not found' });
    expect(logger.error).not.toHaveBeenCalled();
  });

  it('cualquier otro error responde 500 genérico, sin el mensaje interno, y se registra', () => {
    const res = handle(new Error('duplicate key value violates unique constraint "users_pkey"'));

    expect(res.statusCode).toBe(500);
    expect(res.body).toEqual({ success: false, message: 'Error interno del servidor' });
    expect(logger.error).toHaveBeenCalledWith(expect.stringContaining('users_pkey'));
  });

  it('algo que ni siquiera es un Error también da 500 genérico', () => {
    const res = handle('boom');

    expect(res.statusCode).toBe(500);
    expect(res.body).toEqual({ success: false, message: 'Error interno del servidor' });
    expect(logger.error).toHaveBeenCalledWith(expect.stringContaining('boom'));
  });
});

describe('HttpError', () => {
  it('es un Error con status y mensaje', () => {
    const err = new HttpError(400, 'Unknown exercise ids: e9');

    expect(err).toBeInstanceOf(Error);
    expect(err).toMatchObject({ status: 400, message: 'Unknown exercise ids: e9' });
  });
});
