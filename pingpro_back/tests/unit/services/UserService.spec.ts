import { UserService } from '../../../src/services/UserService';
import type { IUserRepository } from '../../../src/interfaces/repositories/IUserRepository';

function fakeRepo(): jest.Mocked<IUserRepository> {
  return {
    getById: jest.fn(),
    createWithUID: jest.fn(),
    update: jest.fn(),
    delete: jest.fn().mockResolvedValue(undefined),
  };
}

describe('UserService.deleteAccount', () => {
  it('borra primero la fila y después la cuenta de Auth', async () => {
    const calls: string[] = [];
    const repo = fakeRepo();
    repo.delete.mockImplementation(async () => {
      calls.push('db');
    });
    const accounts = {
      deleteUser: jest.fn(async () => {
        calls.push('auth');
      }),
    };

    await new UserService(repo, accounts).deleteAccount('u1');

    expect(repo.delete).toHaveBeenCalledWith('u1');
    expect(accounts.deleteUser).toHaveBeenCalledWith('u1');
    expect(calls).toEqual(['db', 'auth']);
  });

  it('si falla la base no toca Auth', async () => {
    const repo = fakeRepo();
    repo.delete.mockRejectedValue(new Error('db down'));
    const accounts = { deleteUser: jest.fn().mockResolvedValue(undefined) };

    await expect(new UserService(repo, accounts).deleteAccount('u1')).rejects.toThrow('db down');
    expect(accounts.deleteUser).not.toHaveBeenCalled();
  });

  it('no exige que la fila exista: un reintento sigue hasta Auth', async () => {
    const repo = fakeRepo();
    repo.getById.mockResolvedValue(null);
    const accounts = { deleteUser: jest.fn().mockResolvedValue(undefined) };

    await new UserService(repo, accounts).deleteAccount('u1');

    expect(repo.getById).not.toHaveBeenCalled();
    expect(accounts.deleteUser).toHaveBeenCalledWith('u1');
  });
});
