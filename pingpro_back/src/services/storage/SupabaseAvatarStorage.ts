/**
 * Fotos de perfil en Supabase Storage, por su API REST.
 *
 * Usa el fetch de Node y la clave service-role en vez de supabase-js: el
 * backend es el único cliente del bucket, igual que con la base de datos, y
 * así no se añade ninguna dependencia. La clave nunca sale en los mensajes de
 * error, que acaban en el log.
 */
import type { IAvatarStorage } from '../../interfaces/storage/IAvatarStorage';
import { UnconfiguredAvatarStorage } from './UnconfiguredAvatarStorage';

const BUCKET = 'avatars';

export class SupabaseAvatarStorage implements IAvatarStorage {
  constructor(
    private readonly baseUrl: string,
    private readonly serviceKey: string,
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  async upload(path: string, png: Buffer): Promise<string> {
    await this.request('upload', `/storage/v1/object/${BUCKET}/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'image/png', 'x-upsert': 'false' },
      body: png,
    });
    return `${this.baseUrl}/storage/v1/object/public/${BUCKET}/${path}`;
  }

  async remove(paths: string[]): Promise<void> {
    if (paths.length === 0) return;
    await this.request('remove', `/storage/v1/object/${BUCKET}`, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prefixes: paths }),
    });
  }

  async list(prefix: string): Promise<string[]> {
    const res = await this.request('list', `/storage/v1/object/list/${BUCKET}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prefix, limit: 1000 }),
    });
    const items: unknown = await res.json();
    if (!Array.isArray(items)) return [];
    return items
      .map((item: unknown) => (item as { name?: unknown } | null)?.name)
      .filter((name): name is string => typeof name === 'string')
      .map((name) => prefix + name);
  }

  publicPrefix(uid: string): string {
    return `${this.baseUrl}/storage/v1/object/public/${BUCKET}/${uid}/`;
  }

  private async request(op: string, path: string, init: RequestInit): Promise<Response> {
    const res = await this.fetchFn(`${this.baseUrl}${path}`, {
      ...init,
      headers: {
        ...(init.headers as Record<string, string>),
        Authorization: `Bearer ${this.serviceKey}`,
        apikey: this.serviceKey,
      },
    });
    if (!res.ok) throw new Error(`Supabase Storage ${op} → ${res.status}`);
    return res;
  }
}

/** El cliente real si están las dos variables; si no, el no configurado. */
export function createAvatarStorage(env: Record<string, string | undefined>): IAvatarStorage {
  const baseUrl = env.SUPABASE_URL;
  const key = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!baseUrl || !key) return new UnconfiguredAvatarStorage();
  return new SupabaseAvatarStorage(baseUrl.replace(/\/+$/, ''), key);
}
