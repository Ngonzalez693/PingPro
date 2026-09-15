/**
 * Contrato de un ejercicio (documento de la colección 'exercises').
 *
 * `sequence` es lo que define el ejercicio: la lista ordenada de golpes.
 * `image` es una ruta de asset de Flutter (p. ej. 'assets/images/exercise_1.jpg'),
 * no una URL — algo a revisar si algún día los usuarios crean ejercicios.
 *
 * El favorito y el completado no van aquí: son de cada usuario y viven en
 * users/{uid}/exerciseStates (IUserExerciseState).
 */
import { ISequenceStep } from "./ISequenceStep";

// Interface for exercise model
export interface IExercise {
  id?: string;
  name: string;
  category: string;
  image: string;
  description?: string;
  sequence: ISequenceStep[];
}
