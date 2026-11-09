import type { IUserRepository } from '../../../src/interfaces/repositories/IUserRepository';
import type { IAvatarStorage } from '../../../src/interfaces/storage/IAvatarStorage';
import { ProfilePhotoService } from '../../../src/services/ProfilePhotoService';

jest.mock('../../../src/utils/logger', () => ({
  __esModule: true,
  default: { warn: jest.fn(), error: jest.fn(), info: jest.fn() },
}));

const PREFIX = 'https://x.supabase.co/storage/v1/object/public/avatars/u1/';
const OLD_URL = `${PREFIX}old.png`;
const NEW_URL = `${PREFIX}n1.png`;
const PNG = Buffer.from([1, 2, 3]);

interface Setup {
  previous: string | null;
  calls: string[];
  users: jest.Mocked<IUserRepository>;
  storage: jest.Mocked<IAvatarStorage>;
  accounts: { setPhotoURL: jest.Mock };
  service: ProfilePhotoService;
}

// Falsos que apuntan el orden de las llamadas. null = el usuario no tiene foto.
function setup(previous: string | null = OLD_URL): Setup {
  const calls: string[] = [];
  const users: jest.Mocked<IUserRepository> = {
    getById: jest.fn().mockResolvedValue({ id: 'u1', email: 'a@b.c', photoURL: previous ?? undefined }),
    createWithUID: jest.fn(),
    update: jest.fn(),
    setPhotoURL: jest.fn(async (_id: string, url: string | null) => {
      calls.push(`db:${url}`);
    }),
    delete: jest.fn(),
  };
  const storage: jest.Mocked<IAvatarStorage> = {
    upload: jest.fn(async (path: string, _png: Buffer) => {
      calls.push(`upload:${path}`);
      return `${PREFIX}${path.split('/')[1]}`;
    }),
    remove: jest.fn(async (paths: string[]) => {
      calls.push(`remove:${paths.join(',')}`);
    }),
    list: jest.fn().mockResolvedValue(['u1/old.png']),
    publicPrefix: jest.fn().mockReturnValue(PREFIX),
  };
  const accounts = {
    setPhotoURL: jest.fn(async (_uid: string, url: string | null) => {
      calls.push(`auth:${url}`);
    }),
  };
  const service = new ProfilePhotoService(users, storage, accounts, () => 'n1');
  return { previous, calls, users, storage, accounts, service };
}

describe('ProfilePhotoService.replace', () => {
  it('sube, guarda en Auth y en la base, y borra la foto anterior', async () => {
    const s = setup();

    await expect(s.service.replace('u1', PNG)).resolves.toBe(NEW_URL);

    expect(s.calls).toEqual(['upload:u1/n1.png', `auth:${NEW_URL}`, `db:${NEW_URL}`, 'remove:u1/old.png']);
  });

  it('una foto anterior de fuera del bucket no se borra', async () => {
    const s = setup('https://lh3.googleusercontent.com/x');

    await s.service.replace('u1', PNG);

    expect(s.storage.remove).not.toHaveBeenCalled();
  });

  it('sin foto anterior no borra nada', async () => {
    const s = setup(null);

    await s.service.replace('u1', PNG);

    expect(s.storage.remove).not.toHaveBeenCalled();
  });

  it('si falla Auth borra la foto nueva y no toca la base', async () => {
    const s = setup();
    s.accounts.setPhotoURL.mockRejectedValueOnce(new Error('auth down'));

    await expect(s.service.replace('u1', PNG)).rejects.toThrow('auth down');

    expect(s.storage.remove).toHaveBeenCalledWith(['u1/n1.png']);
    expect(s.users.setPhotoURL).not.toHaveBeenCalled();
  });

  it('si falla la base devuelve Auth a la foto anterior y borra la nueva', async () => {
    const s = setup();
    s.users.setPhotoURL.mockRejectedValueOnce(new Error('db down'));

    await expect(s.service.replace('u1', PNG)).rejects.toThrow('db down');

    expect(s.accounts.setPhotoURL).toHaveBeenNthCalledWith(1, 'u1', NEW_URL);
    expect(s.accounts.setPhotoURL).toHaveBeenNthCalledWith(2, 'u1', OLD_URL);
    expect(s.storage.remove).toHaveBeenCalledWith(['u1/n1.png']);
  });

  it('si falla borrar la foto anterior, el cambio sigue valiendo', async () => {
    const s = setup();
    s.storage.remove.mockRejectedValueOnce(new Error('storage down'));

    await expect(s.service.replace('u1', PNG)).resolves.toBe(NEW_URL);
  });
});

describe('ProfilePhotoService.remove', () => {
  it('sin foto no llama a nada', async () => {
    const s = setup(null);

    await s.service.remove('u1');

    expect(s.accounts.setPhotoURL).not.toHaveBeenCalled();
    expect(s.users.setPhotoURL).not.toHaveBeenCalled();
    expect(s.storage.remove).not.toHaveBeenCalled();
  });

  it('con foto la quita de Auth y de la base y borra el archivo', async () => {
    const s = setup();

    await s.service.remove('u1');

    expect(s.calls).toEqual(['auth:null', 'db:null', 'remove:u1/old.png']);
  });
});

describe('ProfilePhotoService.removeAllFor', () => {
  it('borra todo lo de la carpeta del usuario', async () => {
    const s = setup();

    await s.service.removeAllFor('u1');

    expect(s.storage.list).toHaveBeenCalledWith('u1/');
    expect(s.storage.remove).toHaveBeenCalledWith(['u1/old.png']);
  });

  // Borrar la cuenta no se bloquea si Supabase está caído (lo eligió el usuario).
  it('si Supabase falla no lanza', async () => {
    const s = setup();
    s.storage.list.mockRejectedValueOnce(new Error('storage down'));

    await expect(s.service.removeAllFor('u1')).resolves.toBeUndefined();
  });
});
