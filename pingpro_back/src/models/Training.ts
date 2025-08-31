import { ITraining } from '@interfaces/models/ITraining';

export class Training implements ITraining {
  id?: string;
  name: string;
  description: string;
  exerciseIds: string[];
  duration: number;
  tags: string[];

  constructor(data: ITraining) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description ?? '';
    this.exerciseIds = data.exerciseIds;
    this.duration = data.duration ?? 0;
    this.tags = data.tags ?? [];
  }
}
