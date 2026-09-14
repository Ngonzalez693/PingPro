/**
 * Progreso de UN usuario sobre UN entrenamiento (documento en
 * users/{uid}/trainingStates/{trainingId}). Equivalente a IUserExerciseState,
 * también con fechas Date en lugar del Timestamp de Firestore.
 *
 * No guarda un porcentaje de avance: la app lo calcula contando cuántos de los
 * exerciseIds están completados.
 */
export interface IUserTrainingState {
  userId: string;
  trainingId: string;
  completedAt?: Date | null;
  updatedAt: Date;
}
