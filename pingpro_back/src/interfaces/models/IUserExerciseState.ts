export interface IUserExerciseState {
  userId: string;
  exerciseId: string;
  isFavorite?: boolean;
  completedAt?: FirebaseFirestore.Timestamp | null;
  updatedAt: FirebaseFirestore.Timestamp;
}