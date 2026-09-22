/**
 * Un paso de la secuencia de un ejercicio: un solo golpe descrito con los
 * códigos de utils/enums.ts.
 *
 * Un ejercicio es un array ordenado de estos pasos. El equivalente en la app es
 * SequenceStep (models/sequence_step_model.dart), que usa int en vez de enums.
 */
import { HitCode, RotationCode, ZoneCode, DirectionCode, SideCode } from '../../utils/enums';

// Interface for exercise sequence
export interface ISequenceStep {
  hit: HitCode;
  rotation: RotationCode;
  zone: ZoneCode;
  direction: DirectionCode;
  side: SideCode;
  // Profundidad del jugador en su propio campo. Libre = sin especificar.
  ownZone: ZoneCode;
}