// Interface for training model
export interface ITraining {
  id?: string;
  name: string;
  description?: string;
  exerciseIds: string[];
  duration?: number;
  tags?: string[];
}
