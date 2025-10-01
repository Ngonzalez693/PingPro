export interface IUserTrainingState {
  userId: string;
  trainingId: string;
  completedAt?: FirebaseFirestore.Timestamp | null;
  updatedAt: FirebaseFirestore.Timestamp;
  progress?: number;
}
