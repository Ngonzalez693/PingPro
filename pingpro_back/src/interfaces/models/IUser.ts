// Interface for user model
export interface IUser {
  id?: string;
  email: string;
  passwordHash: string;
  displayName?: string;
  photoURL?: string;
  roles?: string[];        // ['user', 'admin']
  createdAt?: Date;
  updatedAt?: Date;
}
