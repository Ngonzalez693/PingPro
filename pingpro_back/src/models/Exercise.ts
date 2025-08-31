import { IExercise } from '@interfaces/models/IExercise';

export class Exercise implements IExercise {
  id?: string;
  name: string;
  category: string;
  image: string;
  isFavorite: boolean;
  description: string;
  sequence: IExercise['sequence'];    // Array, every hit of the exercise

  constructor(data: IExercise) {
    this.id = data.id;
    this.name = data.name;
    this.category = data.category;
    this.image = data.image;
    this.isFavorite = data.isFavorite ?? false;
    this.description = data.description ?? '';
    this.sequence = data.sequence;
  }
}
