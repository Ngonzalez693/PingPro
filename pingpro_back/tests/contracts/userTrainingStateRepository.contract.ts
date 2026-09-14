/**
 * Contrato del estado de cada usuario sobre cada entrenamiento
 * (users/{uid}/trainingStates/{trainingId}).
 *
 * Igual que en los ejercicios: un completedAt que nunca se escribió sale como
 * null.
 */
import type { IUserTrainingState } from '../../src/interfaces/models/IUserTrainingState';
import type { IUserTrainingStateRepository } from '../../src/interfaces/repositories/IUserTrainingStateRepository';
import { expectDateBetween } from './dates';
import type { ContractSetup } from './types';

function sortByTraining(states: Array<IUserTrainingState | null>): Array<IUserTrainingState | null> {
  return [...states].sort((a, b) => (a?.trainingId ?? '').localeCompare(b?.trainingId ?? ''));
}

export function userTrainingStateContract(
  name: string,
  setup: ContractSetup<IUserTrainingStateRepository>,
): void {
  describe(`${name} (contrato de estados de entrenamiento)`, () => {
    let repo: IUserTrainingStateRepository;

    beforeEach(async () => {
      await setup.reset();
      repo = setup.createRepository();
    });

    it('sin estados, getState devuelve null y getAllStates []', async () => {
      await expect(repo.getState('u1', 't1')).resolves.toBeNull();
      await expect(repo.getAllStates('u1')).resolves.toEqual([]);
    });

    it('setCompleted guarda cuándo se completó y false lo vuelve null', async () => {
      const before = new Date();
      const completed = await repo.setCompleted('u1', 't1', true);
      const after = new Date();

      expect(completed).toEqual({
        userId: 'u1',
        trainingId: 't1',
        completedAt: expect.any(Date),
        updatedAt: expect.any(Date),
      });
      expectDateBetween(completed.completedAt, before, after);

      const reopened = await repo.setCompleted('u1', 't1', false);

      expect(reopened.completedAt).toBeNull();
    });

    it('getAllStates devuelve solo los estados del usuario pedido', async () => {
      await repo.setCompleted('u1', 't1', true);
      await repo.setCompleted('u1', 't2', true);
      await repo.setCompleted('u2', 't1', true);

      const states = await repo.getAllStates('u1');

      expect(sortByTraining(states)).toEqual(
        sortByTraining([await repo.getState('u1', 't1'), await repo.getState('u1', 't2')]),
      );
    });
  });
}
