import { v2 as cloudinary } from 'cloudinary';
import { IModel3DRepository } from '@/interfaces/repositories/IModel3DRepository';
import FirebaseModel3DRepository from '@/repositories/implementations/FirebaseModel3DRepository';
import { IModel3D } from '@/interfaces/models/IModel3D';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_NAME!,
  api_key: process.env.CLOUDINARY_KEY!,
  api_secret: process.env.CLOUDINARY_SECRET!
});

export default class Model3DService {
  private repo: IModel3DRepository;

  constructor(repo: IModel3DRepository = new FirebaseModel3DRepository()) {
    this.repo = repo;
  }

  async list(): Promise<IModel3D[]> {
    return this.repo.getAll();
  }

  async upload(name: string, filePath: string): Promise<IModel3D> {
    const result = await cloudinary.uploader.upload(filePath, {
      resource_type: 'auto',
      folder: '3d-models'
    });
    const model: IModel3D = {
      name,
      cloudinaryId: result.public_id,
      url: result.secure_url,
      metadata: {
        width: result.width,
        height: result.height,
        format: result.format,
        version: result.version
      },
      createdAt: new Date(),
      updatedAt: new Date()
    };
    return this.repo.create(model);
  }
}