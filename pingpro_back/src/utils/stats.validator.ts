/**
 * Query de GET /api/stats/me/events.
 *
 * La app pide como mucho 6 meses (el periodo mensual); el tope de 400 días
 * deja margen para pedir un año sin cambiar la API y evita que alguien pida
 * todo el historial de golpe.
 */
import Joi from 'joi';

export const STATS_MAX_DAYS = 400;
const DAY_MS = 24 * 60 * 60 * 1000;

export const statsEventsQuerySchema = Joi.object({
  from: Joi.date()
    .iso()
    .max('now')
    .required()
    .custom((value: Date, helpers) => {
      const earliest = Date.now() - STATS_MAX_DAYS * DAY_MS;
      if (value.getTime() < earliest) {
        return helpers.message({ custom: `"from" must be within the last ${STATS_MAX_DAYS} days` });
      }
      return value;
    }),
});
