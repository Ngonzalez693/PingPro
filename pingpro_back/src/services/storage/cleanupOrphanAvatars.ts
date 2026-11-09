/**
 * Limpia las fotos de perfil que quedaron sin dueño.
 *
 * Borrar una cuenta no se bloquea si Supabase está caído (lo eligió el
 * usuario): su carpeta puede quedar en el bucket. Cada carpeta raíz es un uid,
 * así que basta con borrar las de los uids que ya no tienen fila en users.
 */
import type { IUserRepository } from '../../interfaces/repositories/IUserRepository';
import type { IAvatarStorage } from '../../interfaces/storage/IAvatarStorage';

export async function cleanupOrphanAvatars(
  storage: IAvatarStorage,
  users: Pick<IUserRepository, 'getById'>,
): Promise<string[]> {
  const cleaned: string[] = [];
  for (const uid of await storage.list('')) {
    if (await users.getById(uid)) continue;
    await storage.remove(await storage.list(`${uid}/`));
    cleaned.push(uid);
  }
  return cleaned;
}
