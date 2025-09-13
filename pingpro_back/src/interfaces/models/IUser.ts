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
