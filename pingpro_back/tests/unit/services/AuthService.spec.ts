import { auth } from '../../../src/config/firebase';
import { AuthService } from '../../../src/services/AuthService';

// Se mockea el módulo para que ningún test arranque el SDK de Firebase.
jest.mock('../../../src/config/firebase', () => ({
  auth: { deleteUser: jest.fn() },
}));

const deleteUser = jest.mocked(auth.deleteUser);

describe('AuthService.deleteUser', () => {
  beforeEach(() => {
    deleteUser.mockReset();
  });

  it('resuelve cuando Auth borra la cuenta', async () => {
    deleteUser.mockResolvedValue(undefined);

    await expect(new AuthService().deleteUser('u1')).resolves.toBeUndefined();
    expect(deleteUser).toHaveBeenCalledWith('u1');
  });

  it('resuelve si la cuenta ya no existe (reintento tras un borrado a medias)', async () => {
    deleteUser.mockRejectedValue({ code: 'auth/user-not-found' });

    await expect(new AuthService().deleteUser('u1')).resolves.toBeUndefined();
  });

  it('propaga cualquier otro error de Auth', async () => {
    const failure = { code: 'auth/internal-error' };
    deleteUser.mockRejectedValue(failure);

    await expect(new AuthService().deleteUser('u1')).rejects.toBe(failure);
  });
});
