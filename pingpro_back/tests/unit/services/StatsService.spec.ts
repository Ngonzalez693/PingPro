import { StatsService } from '../../../src/services/StatsService';
import type { IStatsEvents } from '../../../src/interfaces/models/IStatsEvents';
import type { IStatsRepository } from '../../../src/interfaces/repositories/IStatsRepository';

describe('StatsService', () => {
  it('getEvents pide los eventos del usuario desde la fecha dada', async () => {
    const events: IStatsEvents = { exerciseCompletions: [], trainingCompletions: [], created: [] };
    const repo: jest.Mocked<IStatsRepository> = { getEvents: jest.fn().mockResolvedValue(events) };
    const from = new Date('2026-09-01T00:00:00.000Z');

    await expect(new StatsService(repo).getEvents('u1', from)).resolves.toBe(events);
    expect(repo.getEvents).toHaveBeenCalledWith('u1', from);
  });
});
