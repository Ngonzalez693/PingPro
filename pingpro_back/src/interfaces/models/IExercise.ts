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
