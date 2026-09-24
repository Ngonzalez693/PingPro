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

    await expect(service.getById('nope', 'u1')).rejects.toMatchObject({
      status: 404,
      message: 'Exercise not found',
    });
  });

  it('getById pregunta con el uid de quien mira', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await service.getById('e1', 'u1');

    expect(exerciseRepo.getById).toHaveBeenCalledWith('e1', 'u1');
  });

  it('getAll pregunta con el uid de quien mira', async () => {
    exerciseRepo.getAll.mockResolvedValue([exercise]);

    await service.getAll('u1');

    expect(exerciseRepo.getAll).toHaveBeenCalledWith('u1');
  });

  it('un ejercicio privado de otro usuario es 404, no un error de permiso', async () => {
    // El repositorio ya lo filtra por viewer: para el servicio es indistinguible
    // de un id que no existe, que es justo lo que se busca.
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.getById('de-otro', 'u1')).rejects.toMatchObject({ status: 404 });
  });

  it('update no escribe nada si el ejercicio no existe', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.update('nope', { name: 'Nuevo' }, null)).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.update).not.toHaveBeenCalled();
  });

  it('delete no borra nada si el ejercicio no existe', async () => {
    exerciseRepo.getById.mockResolvedValue(null);

    await expect(service.delete('nope', null)).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.delete).not.toHaveBeenCalled();
  });

  // update y delete son las operaciones de admin sobre el catálogo: si miraran
  // con un uid podrían tocar un ejercicio privado por su id.
  it('update solo mira el catálogo', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await service.update('e1', { name: 'Nuevo' }, null);

    expect(exerciseRepo.getById).toHaveBeenCalledWith('e1', null);
  });

  it('delete solo mira el catálogo', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await service.delete('e1', null);

    expect(exerciseRepo.getById).toHaveBeenCalledWith('e1', null);
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

  // requireOwned: la lectura con viewer trae catálogo + lo del usuario, así que
  // sin la segunda comprobación un usuario podría editar el catálogo por /me.
  it('un usuario no puede editar un ejercicio del catálogo por la ruta propia', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise); // sin ownerId = catálogo

    await expect(service.update('e1', { name: 'Pisado' }, 'u1')).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.update).not.toHaveBeenCalled();
  });

  it('un usuario no puede borrar un ejercicio del catálogo por la ruta propia', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await expect(service.delete('e1', 'u1')).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.delete).not.toHaveBeenCalled();
  });

  it('un admin no puede editar un ejercicio privado por la ruta de catálogo', async () => {
    exerciseRepo.getById.mockResolvedValue({ ...exercise, ownerId: 'u1' });

    await expect(service.update('e1', { name: 'Pisado' }, null)).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.update).not.toHaveBeenCalled();
  });

  it('el dueño sí edita el suyo', async () => {
    exerciseRepo.getById.mockResolvedValue({ ...exercise, ownerId: 'u1' });

    await service.update('e1', { name: 'Nuevo' }, 'u1');

    expect(exerciseRepo.update).toHaveBeenCalledWith('e1', { name: 'Nuevo' }, 'u1');
  });

  it('create pasa el dueño al repositorio', async () => {
    exerciseRepo.create.mockResolvedValue('e9');

    await service.create(exercise, 'u1');

    expect(exerciseRepo.create).toHaveBeenCalledWith(exercise, 'u1');
  });

  it('el favorito se puede marcar sobre un ejercicio propio, no solo del catálogo', async () => {
    exerciseRepo.getById.mockResolvedValue({ ...exercise, ownerId: 'u1' });
    userStateRepo.setFavorite.mockResolvedValue({
      userId: 'u1',
      exerciseId: 'e1',
      isFavorite: true,
      updatedAt: new Date('2026-09-12T10:00:00.000Z'),
    });

    await service.setFavoriteForUser('u1', 'e1', true);

    // Con su propio uid, no con null: si mirara solo el catálogo, un ejercicio
    // privado no se podría marcar como favorito.
    expect(exerciseRepo.getById).toHaveBeenCalledWith('e1', 'u1');
  });

  it('setCompletedForUser pasa la sesión al repositorio', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await service.setCompletedForUser('u1', 'e1', true, 2);

    expect(userStateRepo.setCompleted).toHaveBeenCalledWith('u1', 'e1', true, 2);
  });

  it('setCompletedForUser sin sesión la guarda como null', async () => {
    exerciseRepo.getById.mockResolvedValue(exercise);

    await service.setCompletedForUser('u1', 'e1', true);

    expect(userStateRepo.setCompleted).toHaveBeenCalledWith('u1', 'e1', true, null);
  });
});
