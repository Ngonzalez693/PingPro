/**
 * Contrato del estado de cada usuario sobre cada ejercicio
 * (users/{uid}/exerciseStates/{exerciseId}).
 *
 * Fija la forma que la app recibe hoy: un completedAt que nunca se escribió
 * sale como null, y un isFavorite que nunca se escribió no aparece. Supabase
 * tendrá que devolver lo mismo (NULL en la columna → campo ausente).
 */
import type { IUserExerciseState } from '../../src/interfaces/models/IUserExerciseState';
import type { IUserExerciseStateRepository } from '../../src/interfaces/repositories/IUserExerciseStateRepository';
import { expectDateBetween } from './dates';
import type { ContractSetup } from './types';

function sortByExercise(states: Array<IUserExerciseState | null>): Array<IUserExerciseState | null> {
  return [...states].sort((a, b) => (a?.exerciseId ?? '').localeCompare(b?.exerciseId ?? ''));
}

export function userExerciseStateContract(
  name: string,
  setup: ContractSetup<IUserExerciseStateRepository>,
): void {
  describe(`${name} (contrato de estados de ejercicio)`, () => {
    let repo: IUserExerciseStateRepository;

    beforeEach(async () => {
      await setup.reset();
      repo = setup.createRepository();
    });

    it('sin estados, getState devuelve null y getAllStates []', async () => {
      await expect(repo.getState('u1', 'e1')).resolves.toBeNull();
      await expect(repo.getAllStates('u1')).resolves.toEqual([]);
    });

    it('setFavorite devuelve el estado completo y getState devuelve lo mismo', async () => {
      const before = new Date();
      const state = await repo.setFavorite('u1', 'e1', true);
      const after = new Date();

      expect(state).toEqual({
        userId: 'u1',
        exerciseId: 'e1',
        isFavorite: true,
        completedAt: null,
        updatedAt: expect.any(Date),
      });
      expectDateBetween(state.updatedAt, before, after);
      await expect(repo.getState('u1', 'e1')).resolves.toEqual(state);
    });

    it('setCompleted guarda cuándo se completó y false lo vuelve null', async () => {
      const before = new Date();
      const completed = await repo.setCompleted('u1', 'e1', true);
      const after = new Date();

      // Creado solo al completar: isFavorite no aparece.
      expect(completed).toEqual({
        userId: 'u1',
        exerciseId: 'e1',
        completedAt: expect.any(Date),
        updatedAt: expect.any(Date),
      });
      expectDateBetween(completed.completedAt, before, after);

      const reopened = await repo.setCompleted('u1', 'e1', false);

      expect(reopened.completedAt).toBeNull();
    });

    it('marcar completado no borra el favorito', async () => {
      await repo.setFavorite('u1', 'e1', true);

      const state = await repo.setCompleted('u1', 'e1', true);

      expect(state.isFavorite).toBe(true);
      expect(state.completedAt).toBeInstanceOf(Date);
    });

    it('cambiar el favorito no borra la fecha de completado', async () => {
      const completed = await repo.setCompleted('u1', 'e1', true);

      const state = await repo.setFavorite('u1', 'e1', false);

      expect(state.isFavorite).toBe(false);
      expect(state.completedAt).toEqual(completed.completedAt);
    });

    it('getAllStates devuelve solo los estados del usuario pedido', async () => {
      await repo.setFavorite('u1', 'e1', true);
      await repo.setCompleted('u1', 'e2', true);
      await repo.setFavorite('u2', 'e1', true);

      const states = await repo.getAllStates('u1');

      expect(sortByExercise(states)).toEqual(
        sortByExercise([await repo.getState('u1', 'e1'), await repo.getState('u1', 'e2')]),
      );
    });
  });
}
