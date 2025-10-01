import { success, error } from '../../../src/utils/apiResponse';
import { HTTP_STATUS } from '../../../src/utils/constants';
import { Response } from 'express';

describe('apiResponse', () => {
  it('success devuelve data correcto', () => {
    const json = jest.fn();
    const res = { status: () => ({ json }) } as any;
    success(res, { foo: 'bar' }, HTTP_STATUS.CREATED);
    expect(json).toHaveBeenCalledWith({ success: true, data: { foo: 'bar' } });
  });

  it('error devuelve mensaje correcto', () => {
    const json = jest.fn();
    const res = { status: () => ({ json }) } as any;
    error(res, 'fail', HTTP_STATUS.BAD_REQUEST);
    expect(json).toHaveBeenCalledWith({ success: false, message: 'fail' });
  });
});