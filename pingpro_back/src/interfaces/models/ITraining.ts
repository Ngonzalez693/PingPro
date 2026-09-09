/**
 * Contrato de un entrenamiento (documento de la colección 'trainings').
 *
 * No guarda los ejercicios embebidos, solo `exerciseIds`: la app los resuelve
 * contra ExercisesState, así que un ejercicio editado se refleja en todos los
 * entrenamientos que lo usan.
 *
 * `duration` está en minutos y es del entrenamiento completo; la pantalla de
 * detalle la divide entre la cantidad de ejercicios.
 */
// Interface for training model
export interface ITraining {
  id?: string;
  name: string;
  category: string;
  image: string;
  description?: string;
  exerciseIds: string[];
  duration?: number;
}
