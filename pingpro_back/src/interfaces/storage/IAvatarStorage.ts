/**
 * Contrato del almacenamiento de fotos de perfil.
 *
 * Los servicios solo conocen esta interfaz: la implementación real habla con
 * Supabase Storage y los tests pasan un falso sin red.
 */
export interface IAvatarStorage {
  /** Sube el PNG a `path` (p. ej. `<uid>/<id>.png`) y devuelve su URL pública. */
  upload(path: string, png: Buffer): Promise<string>;
  /** Borra los objetos dados. Con una lista vacía no hace nada. */
  remove(paths: string[]): Promise<void>;
  /**
   * Lista lo que hay bajo `prefix`. Con '' devuelve las carpetas raíz (los
   * uids); con '<uid>/' devuelve los paths completos de sus objetos.
   */
  list(prefix: string): Promise<string[]>;
  /** Inicio de la URL pública de cualquier objeto de la carpeta del usuario. */
  publicPrefix(uid: string): string;
}
