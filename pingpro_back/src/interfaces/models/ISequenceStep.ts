import { HitCode, RotationCode, ZoneCode, DirectionCode, SideCode } from '@utils/enums';

// Interface for exercise sequence
export interface ISequenceStep {
  hit: HitCode;
  rotation: RotationCode;
  zone: ZoneCode;
  direction: DirectionCode;
  side: SideCode;
}