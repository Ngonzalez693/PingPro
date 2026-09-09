/**
 * Clase de dominio de un modelo 3D.
 * SIN USO — ver la nota en models/Exercise.ts.
 */
import { IModel3D } from '../interfaces/models/IModel3D';

export class Model3D implements IModel3D {
  id?: string;
  name: string;
  url: string;
  createdAt: Date;
  updatedAt: Date;

  constructor(data: IModel3D) {
    this.id = data.id;
    this.name = data.name;
    this.url = data.url;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }
}