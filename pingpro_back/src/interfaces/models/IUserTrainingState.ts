/**
 * Progreso de UN usuario sobre UN entrenamiento (documento en
 * users/{uid}/trainingStates/{trainingId}). Equivalente a IUserExerciseState,
 * también con fechas Date en lugar del Timestamp de Firestore.
 *
 * `progress` está en el modelo pero hoy nadie lo escribe: la app calcula el
 * porcentaje contando cuántos de los exerciseIds están completados.
 */
export interface IUserTrainingState {
  userId: string;
  trainingId: string;
  completedAt?: Date | null;
  updatedAt: Date;
  progress?: number;
}
