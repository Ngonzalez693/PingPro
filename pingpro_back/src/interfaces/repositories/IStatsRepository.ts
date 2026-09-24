/**
 * Contrato de lectura de estadísticas. Solo lectura: las finalizaciones las
 * escriben los repositorios de estado.
 */
import type { IStatsEvents } from '../models/IStatsEvents';

export interface IStatsRepository {
  // Todo lo del usuario con fecha >= from, en orden cronológico.
  getEvents(userId: string, from: Date): Promise<IStatsEvents>;
}
