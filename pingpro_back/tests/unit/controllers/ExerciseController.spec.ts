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
    req = { params: { id: '123' }, body: {} };
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
});