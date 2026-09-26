import { Request, Response } from 'express';
import ExerciseController from '../../../src/controllers/ExerciseController';
import { ExerciseService } from '../../../src/services/ExerciseService';
import { success } from '../../../src/utils/apiResponse';
import { HTTP_STATUS } from '../../../src/utils/constants';

jest.mock('../../../src/services/ExerciseService');

describe('ExerciseController', () => {
  let req: Partial<Request>;
  let res: Partial<Response>;
  let statusMock: jest.Mock;
  let jsonMock: jest.Mock;

  beforeEach(() => {
    // El servicio está mockeado a nivel de prototipo y las llamadas se
    // acumularían entre pruebas.
    jest.clearAllMocks();

    // El uid lo deja authMiddleware: el listado lo necesita para saber qué
    // ejercicios privados incluir.
    req = { params: { id: '123' }, body: {}, user: { uid: 'u1' } };
    jsonMock = jest.fn();
    statusMock = jest.fn(() => ({ json: jsonMock }));
    res = { status: statusMock } as any;
  });

  it('getAll devuelve 200 con datos', async () => {
    const fakeData = [{ id: '1', name: 'Ping-pong drill' }];
    (ExerciseService.prototype.getAll as jest.Mock).mockResolvedValue(fakeData);

    await ExerciseController.getAll(req as Request, res as Response, jest.fn());

    expect(statusMock).toHaveBeenCalledWith(HTTP_STATUS.OK);
    expect(jsonMock).toHaveBeenCalledWith({ success: true, data: fakeData });
  });

  it('getAll pide el listado con el uid de quien llama', async () => {
    (ExerciseService.prototype.getAll as jest.Mock).mockResolvedValue([]);

    await ExerciseController.getAll(req as Request, res as Response, jest.fn());

    expect(ExerciseService.prototype.getAll).toHaveBeenCalledWith('u1');
  });

  it('getAll devuelve 401 sin sesión', async () => {
    (ExerciseService.prototype.getAll as jest.Mock).mockResolvedValue([]);

    await ExerciseController.getAll({ ...req, user: undefined } as Request, res as Response, jest.fn());

    expect(statusMock).toHaveBeenCalledWith(HTTP_STATUS.UNAUTHORIZED);
    expect(ExerciseService.prototype.getAll).not.toHaveBeenCalled();
  });

  it('completed pasa la sesión del body al servicio', async () => {
    (ExerciseService.prototype.setCompletedForUser as jest.Mock).mockResolvedValue({});

    await ExerciseController.completed(
      { ...req, body: { completed: true, session: 2 } } as Request,
      res as Response,
      jest.fn(),
    );

    expect(ExerciseService.prototype.setCompletedForUser).toHaveBeenCalledWith('u1', '123', true, 2);
  });

  it('completed sin sesión pasa null', async () => {
    (ExerciseService.prototype.setCompletedForUser as jest.Mock).mockResolvedValue({});

    await ExerciseController.completed({ ...req, body: { completed: true } } as Request, res as Response, jest.fn());

    expect(ExerciseService.prototype.setCompletedForUser).toHaveBeenCalledWith('u1', '123', true, null);
  });

  it('un error del servicio no se responde aquí: va a errorHandler con next', async () => {
    const failure = new Error('relation "exercises" does not exist');
    (ExerciseService.prototype.getById as jest.Mock).mockRejectedValue(failure);
    const next = jest.fn();

    await ExerciseController.getById(req as Request, res as Response, next);

    expect(next).toHaveBeenCalledWith(failure);
    expect(statusMock).not.toHaveBeenCalled();
  });
});