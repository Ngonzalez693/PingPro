import { ExerciseService } from '../../../src/services/ExerciseService';
import type { IExercise } from '../../../src/interfaces/models/IExercise';
import type { IUserExerciseState } from '../../../src/interfaces/models/IUserExerciseState';
import type { IExerciseRepository } from '../../../src/interfaces/repositories/IExerciseRepository';
import type { IUserExerciseStateRepository } from '../../../src/interfaces/repositories/IUserExerciseStateRepository';

// Repositorios falsos que se pasan por constructor: lo que se prueba son las
// reglas del servicio (qué es un 404 y qué no se llega a escribir), no la base
// de datos.
function fakeExerciseRepo(): jest.Mocked<IExerciseRepository> {
  return {
    getAll: jest.fn(),
    getById: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    exists: jest.fn(),
  };
}

function fakeUserStateRepo(): jest.Mocked<IUserExerciseStateRepository> {
  return {
    setFavorite: jest.fn(),
    setCompleted: jest.fn(),
    getState: jest.fn(),
    getAllStates: jest.fn(),
  };
}

const exercise: IExercise = {
  id: 'e1',
  name: 'Topspin cruzado',
  category: 'Ataque',
  image: 'assets/images/exercise_1.jpg',
  sequence: [],
};

describe('ExerciseService', () => {
  let exerciseRepo: jest.Mocked<IExerciseRepository>;
  let userStateRepo: jest.Mocked<IUserExerciseStateRepository>;
  let service: ExerciseService;

  beforeEach(() => {
    exerciseRepo = fakeExerciseRepo();
    userStateRepo = fakeUserStateRepo();
    service = new ExerciseService(exerciseRepo, userStateRepo);
  });

  it('getById responde 404 si el ejercicio no existe', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.getById('nope')).rejects.toMatchObject({
      status: 404,
      message: 'Exercise not found',
    });
  });

  it('update no escribe nada si el ejercicio no existe', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.update('nope', { name: 'Nuevo' })).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.update).not.toHaveBeenCalled();
  });

  it('delete no borra nada si el ejercicio no existe', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.delete('nope')).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.delete).not.toHaveBeenCalled();
  });

  it('setFavoriteForUser no crea estados huérfanos para ejercicios inexistentes', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.setFavoriteForUser('u1', 'nope', true)).rejects.toMatchObject({ status: 404 });
    expect(userStateRepo.setFavorite).not.toHaveBeenCalled();
  });

  it('setFavoriteForUser guarda el favorito si el ejercicio existe', async () => {
    const state: IUserExerciseState = {
      userId: 'u1',
      exerciseId: 'e1',
      isFavorite: true,
      updatedAt: new Date('2026-09-12T10:00:00.000Z'),
    };
    exerciseRepo.getById.mockResolvedValue(exercise);
    userStateRepo.setFavorite.mockResolvedValue(state);

    await expect(service.setFavoriteForUser('u1', 'e1', true)).resolves.toBe(state);
    expect(userStateRepo.setFavorite).toHaveBeenCalledWith('u1', 'e1', true);
  });
});
