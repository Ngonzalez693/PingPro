import { HitCode, RotationCode, ZoneCode, DirectionCode, SideCode } from '@utils/enums';


export interface ISequenceStep {
  hit: HitCode;
  rotation: RotationCode;
  zone: ZoneCode;
  direction: DirectionCode;
  side: SideCode;
}

export interface IExercise {
  id?: string;
  name: string;
  category: string;
  image: string;
  isFavorite?: boolean;
  description?: string;
  sequence: ISequenceStep[];
}
