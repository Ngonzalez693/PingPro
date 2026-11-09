import type { IAvatarStorage } from '../../../src/interfaces/storage/IAvatarStorage';
import { cleanupOrphanAvatars } from '../../../src/services/storage/cleanupOrphanAvatars';

describe('cleanupOrphanAvatars', () => {
  it('borra solo las carpetas de usuarios que ya no existen', async () => {
    const storage: jest.Mocked<IAvatarStorage> = {
      upload: jest.fn(),
      remove: jest.fn().mockResolvedValue(undefined),
      list: jest.fn(async (prefix: string) => (prefix === '' ? ['u1', 'u2'] : [`${prefix}a.png`])),
      publicPrefix: jest.fn(),
    };
    const users = {
      getById: jest.fn(async (id: string) => (id === 'u1' ? { id: 'u1', email: 'a@b.c' } : null)),
    };

    const cleaned = await cleanupOrphanAvatars(storage, users);

    expect(cleaned).toEqual(['u2']);
    expect(storage.remove).toHaveBeenCalledTimes(1);
    expect(storage.remove).toHaveBeenCalledWith(['u2/a.png']);
  });
});
