/**
 * Reglas de la foto de perfil.
 *
 * La URL vive en dos sitios que tienen que coincidir: users.photo_url (lo lee
 * el perfil de la app) y el photoURL de Firebase Auth (lo lee la pestaña
 * Perfil). Si un paso falla se deshacen los anteriores, para que nunca
 * queden distintos ni quede una foto subida que nadie usa.
 *
 * Solo se borran objetos de la carpeta del propio usuario en el bucket: una
 * URL antigua de otro sitio (importada de Firestore) se sobrescribe sin más.
 */
import { randomUUID } from 'crypto';
import type { IUserRepository } from '../interfaces/repositories/IUserRepository';
import type { IAvatarStorage } from '../interfaces/storage/IAvatarStorage';
import logger from '../utils/logger';
import type { AuthService } from './AuthService';

type PhotoAccounts = Pick<AuthService, 'setPhotoURL'>;

export class ProfilePhotoService {
  constructor(
    private readonly users: IUserRepository,
    private readonly storage: IAvatarStorage,
    private readonly accounts: PhotoAccounts,
    private readonly newId: () => string = randomUUID,
  ) {}

  /** Cambia la foto por el PNG dado y devuelve la URL nueva. */
  async replace(uid: string, png: Buffer): Promise<string> {
    const previous = await this.currentPhoto(uid);
    const path = `${uid}/${this.newId()}.png`;
    const url = await this.storage.upload(path, png);

    try {
      await this.accounts.setPhotoURL(uid, url);
    } catch (err) {
      await this.discard(path);
      throw err;
    }

    try {
      await this.users.setPhotoURL(uid, url);
    } catch (err) {
      await this.accounts.setPhotoURL(uid, previous ?? null);
      await this.discard(path);
      throw err;
    }

    await this.deleteOwned(uid, previous);
    return url;
  }

  /** Quita la foto; sin foto no hace nada. */
  async remove(uid: string): Promise<void> {
    const previous = await this.currentPhoto(uid);
    if (!previous) return;

    await this.accounts.setPhotoURL(uid, null);
    await this.users.setPhotoURL(uid, null);
    await this.deleteOwned(uid, previous);
  }

  /**
   * Borra todo lo de la carpeta del usuario. Nunca lanza: borrar la cuenta no
   * se bloquea si Supabase está caído, y lo que quede lo limpia el script de
   * fotos huérfanas.
   */
  async removeAllFor(uid: string): Promise<void> {
    try {
      await this.storage.remove(await this.storage.list(`${uid}/`));
    } catch (err) {
      logger.error(`No se pudieron borrar las fotos de ${uid}: ${errorText(err)}`);
    }
  }

  private async currentPhoto(uid: string): Promise<string | undefined> {
    return (await this.users.getById(uid))?.photoURL;
  }

  // La foto vieja ya no la usa nadie: si no se puede borrar, solo se registra.
  private async deleteOwned(uid: string, url: string | undefined): Promise<void> {
    const prefix = this.storage.publicPrefix(uid);
    if (!url || !prefix || !url.startsWith(prefix)) return;
    const path = `${uid}/${url.slice(prefix.length)}`;
    try {
      await this.storage.remove([path]);
    } catch (err) {
      logger.warn(`No se pudo borrar la foto anterior ${path}: ${errorText(err)}`);
    }
  }

  // Deshacer una subida: si falla, el error que importa es el original.
  private async discard(path: string): Promise<void> {
    try {
      await this.storage.remove([path]);
    } catch (err) {
      logger.warn(`No se pudo borrar la foto descartada ${path}: ${errorText(err)}`);
    }
  }
}

function errorText(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}
