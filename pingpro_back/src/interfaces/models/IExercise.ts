/**
 * Contrato de un ejercicio (documento de la colección 'exercises').
 *
 * `sequence` es lo que define el ejercicio: la lista ordenada de golpes.
 * `image` es una ruta de asset de Flutter (p. ej. 'assets/images/exercise_1.jpg'),
 * no una URL: los ejercicios creados por un usuario eligen entre las imágenes
 * que ya vienen en la app.
 *
 * `ownerId` ausente = ejercicio del catálogo, visible para todos. Con valor =
 * privado de ese usuario, que es el único que lo ve. Nunca llega del cliente:
 * lo pone el servidor a partir del uid del token.
 *
 * El favorito y el completado no van aquí: son de cada usuario y viven en
 * users/{uid}/exerciseStates (IUserExerciseState).
 */
import { ISequenceStep } from "./ISequenceStep";

// Interface for exercise model
export interface IExercise {
  id?: string;
  ownerId?: string;
  name: string;
  category: string;
  image: string;
  description?: string;
  sequence: ISequenceStep[];
}
