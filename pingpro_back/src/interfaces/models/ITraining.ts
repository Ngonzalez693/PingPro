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
