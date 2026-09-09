/**
 * Progreso de UN usuario sobre UN ejercicio (documento en
 * users/{uid}/exerciseStates/{exerciseId}).
 *
 * Separar esto del catálogo permite que los ejercicios sean compartidos y de
 * solo lectura, mientras cada usuario lleva su propio avance.
 *
 * completedAt guarda la fecha, no un booleano: sobre esas fechas se construyen
 * las gráficas de estadísticas.
 */
export interface IUserExerciseState {
  userId: string;
  exerciseId: string;
  isFavorite?: boolean;
  completedAt?: FirebaseFirestore.Timestamp | null;
  updatedAt: FirebaseFirestore.Timestamp;
}