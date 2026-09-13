import { ExerciseService } from '../../../src/services/ExerciseService';
import { FirebaseExerciseRepository } from '../../../src/repositories/implementations/FirebaseExerciseRepository';
import FirebaseUserExerciseStateRepository from '../../../src/repositories/implementations/FirebaseUserExerciseStateRepository';
import type { IExercise } from '../../../src/interfaces/models/IExercise';
import type { IUserExerciseState } from '../../../src/interfaces/models/IUserExerciseState';

// Se simulan los dos repositorios: lo que se prueba son las reglas del
// servicio (qué es un 404 y qué no se llega a escribir), no Firestore.
jest.mock('../../../src/repositories/implementations/FirebaseExerciseRepository');
jest.mock('../../../src/repositories/implementations/FirebaseUserExerciseStateRepository');

const exercise: IExercise = {
  id: 'e1',
  name: 'Topspin cruzado',
  category: 'Ataque',
  image: 'assets/images/exercise_1.jpg',
  sequence: [],
};

describe('ExerciseService', () => {
  let service: ExerciseService;
  let exerciseRepo: jest.Mocked<FirebaseExerciseRepository>;
  let userStateRepo: jest.Mocked<FirebaseUserExerciseStateRepository>;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new ExerciseService();
    // El servicio crea sus repositorios por dentro (hasta el PR D): se recogen
    // las instancias simuladas que acaba de construir.
    exerciseRepo = jest.mocked(FirebaseExerciseRepository).mock
      .instances[0] as jest.Mocked<FirebaseExerciseRepository>;
    userStateRepo = jest.mocked(FirebaseUserExerciseStateRepository).mock
      .instances[0] as jest.Mocked<FirebaseUserExerciseStateRepository>;
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
