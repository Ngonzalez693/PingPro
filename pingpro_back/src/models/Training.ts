/**
 * Clase de dominio de un entrenamiento (defaults sobre ITraining).
 * SIN USO — ver la nota en models/Exercise.ts.
 */
import { ITraining } from '../interfaces/models/ITraining';

export class Training implements ITraining {
  id?: string;
  name: string;
  category: string;
  image: string;
  description: string;
  exerciseIds: string[];
  duration: number;

  constructor(data: ITraining) {
    this.id = data.id;
    this.name = data.name;
    this.category = data.category;
    this.image = data.image;
    this.description = data.description ?? '';
    this.exerciseIds = data.exerciseIds;
    this.duration = data.duration ?? 0;
  }
}
