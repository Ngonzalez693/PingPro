/**
 * Progreso de UN usuario sobre UN ejercicio (documento en
 * users/{uid}/exerciseStates/{exerciseId}).
 *
 * Separar esto del catálogo permite que los ejercicios sean compartidos y de
 * solo lectura, mientras cada usuario lleva su propio avance.
 *
 * completedAt guarda la fecha, no un booleano: sobre esas fechas se construyen
 * las gráficas de estadísticas.
 *
 * Las fechas son Date y no el Timestamp de Firestore: así la API las envía como
 * texto ISO 8601 y el dominio no depende de la base de datos. La conversión se
 * hace en el repositorio.
 */
export interface IUserExerciseState {
  userId: string;
  exerciseId: string;
  isFavorite?: boolean;
  completedAt?: Date | null;
  updatedAt: Date;
}
