/**
 * Esquema Joi de un ejercicio, usado por validateBody en exerciseRoutes (POST y
 * PUT).
 *
 * Cada código de la secuencia tiene que ser un valor de su enum
 * (utils/enums.ts): un hit: 99 dejaría al mapper 3D sin animación. La categoría
 * tiene que ser una de EXERCISE_CATEGORIES.
 *
 * No acepta isFavorite ni completedAt: son de cada usuario y se guardan con
 * /:id/favorite y /:id/completed.
 */
import Joi from 'joi';
import { EXERCISE_CATEGORIES } from './constants';
import { DirectionCode, HitCode, RotationCode, SideCode, ZoneCode } from './enums';

// Un enum numérico de TypeScript guarda también los nombres (reverse mapping):
// solo interesan los números.
function numericValues(codes: object): number[] {
  return Object.values(codes).filter((value): value is number => typeof value === 'number');
}

const code = (codes: object) => Joi.number().integer().valid(...numericValues(codes)).required();

// Info to validate exercises
export const exerciseSchema = Joi.object({
  name: Joi.string().required(),
  category: Joi.string().valid(...EXERCISE_CATEGORIES).required(),
  image: Joi.string().required(),
  description: Joi.string().allow('').optional(),
  sequence: Joi.array()
    .items(
      Joi.object({
        hit: code(HitCode),
        rotation: code(RotationCode),
        zone: code(ZoneCode),
        direction: code(DirectionCode),
        side: code(SideCode),
      })
    )
    .min(1)
    .required(),
});
