/**
 * Almacenamiento de fotos cuando faltan las variables de Supabase (tests, o
 * un entorno de desarrollo sin el bucket).
 *
 * Subir responde 503 para que la app enseñe que las fotos no están
 * disponibles. Borrar y listar no hacen nada: sin bucket no pudo subirse
 * ninguna foto, así que no hay nada que limpiar y borrar una cuenta sigue
 * funcionando.
 */
import type { IAvatarStorage } from '../../interfaces/storage/IAvatarStorage';
import { HTTP_STATUS } from '../../utils/constants';
import { HttpError } from '../../utils/httpError';

export class UnconfiguredAvatarStorage implements IAvatarStorage {
  async upload(): Promise<string> {
    throw new HttpError(HTTP_STATUS.SERVICE_UNAVAILABLE, 'Las fotos de perfil no están disponibles');
  }

  async remove(): Promise<void> {}

  async list(): Promise<string[]> {
    return [];
  }

  publicPrefix(): string {
    return '';
  }
}
