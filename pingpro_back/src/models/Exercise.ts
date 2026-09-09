/**
 * Clase de dominio de un ejercicio: aplica los valores por defecto que la
 * interfaz deja opcionales (isFavorite, description).
 *
 * SIN USO. Ningún archivo de src/ importa esta clase — servicios y repositorios
 * trabajan con la interfaz IExercise directamente. Lo mismo pasa con las otras
 * clases de src/models/. O se adoptan (instanciándolas en los repositorios para
 * garantizar los defaults) o se eliminan.
 */
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
