/**
 * Contrato del perfil de usuario (documento users/{uid}).
 *
 * `id` es siempre el uid de Firebase Auth. Aquí solo van datos de perfil: las
 * credenciales las administra Firebase Auth, nunca esta colección.
 */
// Interface for user model
export interface IUser {
  id?: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  roles?: string[];
  createdAt?: Date;
  updatedAt?: Date;
}
