import {
  SupabaseAvatarStorage,
  createAvatarStorage,
} from '../../../src/services/storage/SupabaseAvatarStorage';
import { UnconfiguredAvatarStorage } from '../../../src/services/storage/UnconfiguredAvatarStorage';
import { HttpError } from '../../../src/utils/httpError';

const BASE = 'https://x.supabase.co';
const KEY = 'service-key-secret';

interface Recorded {
  url: string;
  init: RequestInit;
}

// Un fetch falso que guarda cada petición y responde lo que se le diga.
function fakeFetch(respond: (url: string) => Response = () => new Response('{}', { status: 200 })) {
  const calls: Recorded[] = [];
  const fn = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, init: init ?? {} });
    return respond(url);
  }) as typeof fetch;
  return { fn, calls };
}

function header(init: RequestInit, name: string): string | undefined {
  return new Headers(init.headers).get(name) ?? undefined;
}

describe('SupabaseAvatarStorage', () => {
  it('sube el PNG con las cabeceras de la clave y devuelve la URL pública', async () => {
    const { fn, calls } = fakeFetch();
    const png = Buffer.from([1, 2, 3]);

    const url = await new SupabaseAvatarStorage(BASE, KEY, fn).upload('u1/a.png', png);

    expect(url).toBe(`${BASE}/storage/v1/object/public/avatars/u1/a.png`);
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe(`${BASE}/storage/v1/object/avatars/u1/a.png`);
    expect(calls[0].init.method).toBe('POST');
    expect(header(calls[0].init, 'authorization')).toBe(`Bearer ${KEY}`);
    expect(header(calls[0].init, 'apikey')).toBe(KEY);
    expect(header(calls[0].init, 'content-type')).toBe('image/png');
    expect(header(calls[0].init, 'x-upsert')).toBe('false');
    expect(calls[0].init.body).toEqual(png);
  });

  it('borra los paths con un DELETE de prefijos', async () => {
    const { fn, calls } = fakeFetch();

    await new SupabaseAvatarStorage(BASE, KEY, fn).remove(['u1/a.png']);

    expect(calls[0].url).toBe(`${BASE}/storage/v1/object/avatars`);
    expect(calls[0].init.method).toBe('DELETE');
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ prefixes: ['u1/a.png'] });
  });

  it('borrar una lista vacía no hace ninguna petición', async () => {
    const { fn, calls } = fakeFetch();

    await new SupabaseAvatarStorage(BASE, KEY, fn).remove([]);

    expect(calls).toHaveLength(0);
  });

  it('lista una carpeta y devuelve los paths completos', async () => {
    const { fn, calls } = fakeFetch(() => new Response(JSON.stringify([{ name: 'a.png' }]), { status: 200 }));

    const paths = await new SupabaseAvatarStorage(BASE, KEY, fn).list('u1/');

    expect(paths).toEqual(['u1/a.png']);
    expect(calls[0].url).toBe(`${BASE}/storage/v1/object/list/avatars`);
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ prefix: 'u1/', limit: 1000 });
  });

  it('si Supabase falla, el error no lleva la clave', async () => {
    const { fn } = fakeFetch(() => new Response('boom', { status: 500 }));

    const result = new SupabaseAvatarStorage(BASE, KEY, fn).upload('u1/a.png', Buffer.from([1]));

    await expect(result).rejects.toThrow('500');
    await expect(result).rejects.not.toThrow(KEY);
  });

  it('el prefijo público de un usuario es su carpeta en el bucket', () => {
    const storage = new SupabaseAvatarStorage(BASE, KEY, fakeFetch().fn);

    expect(storage.publicPrefix('u1')).toBe(`${BASE}/storage/v1/object/public/avatars/u1/`);
  });
});

describe('createAvatarStorage', () => {
  it('sin las variables de Supabase devuelve el almacenamiento no configurado', async () => {
    const storage = createAvatarStorage({});

    expect(storage).toBeInstanceOf(UnconfiguredAvatarStorage);
    const upload = storage.upload('u1/a.png', Buffer.from([1]));
    await expect(upload).rejects.toBeInstanceOf(HttpError);
    await expect(upload).rejects.toMatchObject({ status: 503 });
    await expect(storage.remove(['u1/a.png'])).resolves.toBeUndefined();
    await expect(storage.list('u1/')).resolves.toEqual([]);
  });

  it('con las dos variables devuelve el cliente de Supabase', () => {
    const storage = createAvatarStorage({ SUPABASE_URL: BASE, SUPABASE_SERVICE_ROLE_KEY: KEY });

    expect(storage).toBeInstanceOf(SupabaseAvatarStorage);
  });
});

describe('Supabase en los tests', () => {
  // tests/setup.ts las vacía antes de que nada cargue el .env: con las claves
  // reales en el .env local, los tests subirían archivos al bucket de verdad.
  it('las variables de Supabase llegan vacías a los tests', () => {
    expect(process.env.SUPABASE_URL).toBe('');
    expect(process.env.SUPABASE_SERVICE_ROLE_KEY).toBe('');
    expect(createAvatarStorage(process.env)).toBeInstanceOf(UnconfiguredAvatarStorage);
  });
});

describe('SupabaseAvatarStorage: tiempo límite', () => {
  // Si Supabase se cuelga, borrar una cuenta no puede quedarse esperando.
  it('cada petición lleva una señal para cortarla', async () => {
    const { fn, calls } = fakeFetch();

    await new SupabaseAvatarStorage(BASE, KEY, fn).remove(['u1/a.png']);

    expect(calls[0].init.signal).toBeInstanceOf(AbortSignal);
  });
});
