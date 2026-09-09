/**
 * Clase de dominio del perfil de usuario (defaults sobre IUser: rol 'user',
 * fechas de creación).
 * SIN USO — ver la nota en models/Exercise.ts.
 */
import { IUser } from '@interfaces/models/IUser';

export class User implements IUser {
  id?: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  roles: string[];
  createdAt: Date;
  updatedAt: Date;

  constructor(data: IUser) {
    this.id = data.id;
    this.email = data.email;
    this.displayName = data.displayName ?? '';
    this.photoURL = data.photoURL ?? '';
    this.roles = data.roles ?? ['user'];
    this.createdAt = data.createdAt ?? new Date();
    this.updatedAt = data.updatedAt ?? new Date();
  }
}
