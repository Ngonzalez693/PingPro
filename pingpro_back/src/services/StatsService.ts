/**
 * Estadísticas del usuario. Devuelve eventos sueltos y no agregados: agrupar
 * en días, semanas o meses depende de la hora local del teléfono, y eso lo
 * hace la app (spec del 2026-09-24).
 */
import type { IStatsEvents } from '../interfaces/models/IStatsEvents';
import type { IStatsRepository } from '../interfaces/repositories/IStatsRepository';

export class StatsService {
  // Lo recibe de src/container.ts: el servicio solo conoce la interfaz.
  constructor(private readonly statsRepo: IStatsRepository) {}

  async getEvents(userId: string, from: Date): Promise<IStatsEvents> {
    return this.statsRepo.getEvents(userId, from);
  }
}
