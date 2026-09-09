/**
 * Contrato de un ejercicio (documento de la colección 'exercises').
 *
 * `sequence` es lo que define el ejercicio: la lista ordenada de golpes.
 * `image` es una ruta de asset de Flutter (p. ej. 'assets/images/exercise_1.jpg'),
 * no una URL — algo a revisar si algún día los usuarios crean ejercicios.
 *
 * isFavorite y completedAt aparecen aquí por compatibilidad, pero el estado real
 * por usuario vive en users/{uid}/exerciseStates, no en este documento.
 */
import { ISequenceStep } from "./ISequenceStep";

// Interface for exercise model
export interface IExercise {
  id?: string;
  name: string;
  category: string;
  image: string;
  isFavorite?: boolean;
  completedAt?: Date | null;
  description?: string;
  sequence: ISequenceStep[];
}
