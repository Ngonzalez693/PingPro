/**
 * Esquema Joi de un ejercicio, usado por validateBody en exerciseRoutes (POST y
 * PUT).
 *
 * Cada código de la secuencia tiene que ser un valor de su enum
 * (utils/enums.ts): un hit: 99 dejaría al mapper 3D sin animación. Además,
 * algunos golpes solo admiten ciertas rotaciones o solo se juegan desde el
 * fondo del propio campo. La categoría tiene que ser una de
 * EXERCISE_CATEGORIES.
 *
 * No acepta isFavorite ni completedAt: son de cada usuario y se guardan con
 * /:id/favorite y /:id/completed.
 */
import Joi from 'joi';
import type { ISequenceStep } from '../interfaces/models/ISequenceStep';
import { EXERCISE_CATEGORIES } from './constants';
import { DirectionCode, HitCode, RotationCode, SideCode, ZoneCode } from './enums';

// Un enum numérico de TypeScript guarda también los nombres (reverse mapping):
// solo interesan los números.
function numericValues(codes: object): number[] {
  return Object.values(codes).filter((value): value is number => typeof value === 'number');
}

const code = (codes: object) => Joi.number().integer().valid(...numericValues(codes)).required();

// Golpes que solo admiten algunas rotaciones; los demás admiten todas.
// Espejo de allowedRotations en pingpro_front/lib/core/stroke_codes.dart.
const ALLOWED_ROTATIONS: Partial<Record<HitCode, RotationCode[]>> = {
  [HitCode.HOOK]: [RotationCode.BACK_SPIN],
  [HitCode.GLOBO]: [RotationCode.TOPSPIN, RotationCode.SIDE_SPIN_R, RotationCode.SIDE_SPIN_L, RotationCode.DRIVE],
  [HitCode.SMASH]: [RotationCode.TOPSPIN, RotationCode.DRIVE],
};

// Golpes que solo se juegan desde el fondo del propio campo.
// Espejo de hitsAvailableFrom en pingpro_front/lib/core/stroke_codes.dart.
const LONG_ONLY_HITS: HitCode[] = [HitCode.GLOBO, HitCode.SMASH];

function checkHitRules(step: ISequenceStep, helpers: Joi.CustomHelpers) {
  const allowed = ALLOWED_ROTATIONS[step.hit];
  if (allowed && !allowed.includes(step.rotation)) {
    return helpers.message({ custom: 'rotation no está permitida para ese golpe' });
  }
  if (LONG_ONLY_HITS.includes(step.hit) && step.ownZone !== ZoneCode.LARGO) {
    return helpers.message({ custom: 'ownZone tiene que ser Largo para ese golpe' });
  }
  return step;
}

const sequenceStep = Joi.object({
  hit: code(HitCode),
  rotation: code(RotationCode),
  zone: code(ZoneCode),
  direction: code(DirectionCode),
  side: code(SideCode),
  // Opcional: las versiones de la app anteriores a este campo no lo envían, y
  // entonces la profundidad propia queda sin especificar.
  ownZone: Joi.number().integer().valid(...numericValues(ZoneCode)).default(ZoneCode.LIBRE),
}).custom(checkHitRules);

// Info to validate exercises
export const exerciseSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().valid(...EXERCISE_CATEGORIES).required(),
  image: Joi.string().required(),
  description: Joi.string().allow('').optional(),
  sequence: Joi.array().items(sequenceStep).min(1).required(),
});
