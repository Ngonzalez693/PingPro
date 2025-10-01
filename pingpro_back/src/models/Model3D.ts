import { IModel3D } from '@/interfaces/models/IModel3D';

export class Model3D implements IModel3D {
  id?: string;
  name: string;
  cloudinaryId: string;
  url: string;
  metadata?: {
    width?: number;
    height?: number;
    format?: string;
    version?: number;
  };
  createdAt: Date;
  updatedAt: Date;

  constructor(data: IModel3D) {
    this.id = data.id;
    this.name = data.name;
    this.cloudinaryId = data.cloudinaryId;
    this.url = data.url;
    this.metadata = data.metadata;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }
}