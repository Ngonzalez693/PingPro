export interface IModel3D {
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
}