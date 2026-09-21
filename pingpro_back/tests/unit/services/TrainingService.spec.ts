import { TrainingService } from '../../../src/services/TrainingService';
import type { ITraining } from '../../../src/interfaces/models/ITraining';
import type { IExerciseRepository } from '../../../src/interfaces/repositories/IExerciseRepository';
import type { ITrainingRepository } from '../../../src/interfaces/repositories/ITrainingRepository';
import type { IUserTrainingStateRepository } from '../../../src/interfaces/repositories/IUserTrainingStateRepository';

// Repositorios falsos que se pasan por constructor, como en
// ExerciseService.spec.ts: se prueban las reglas del servicio, no la base de
// datos.
function fakeTrainingRepo(): jest.Mocked<ITrainingRepository> {
  return {
    getAll: jest.fn(),
    getById: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    exists: jest.fn(),
  };
}

function fakeTrainingStateRepo(): jest.Mocked<IUserTrainingStateRepository> {
  return {
    setCompleted: jest.fn(),
    getState: jest.fn(),
    getAllStates: jest.fn(),
  };
}

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

const training: ITraining = {
  id: 't1',
  name: 'Calentamiento',
  category: 'Grado',
  image: 'assets/images/training_1.jpg',
  exerciseIds: ['e1', 'e2'],
  duration: 20,
};

describe('TrainingService', () => {
  let trainingRepo: jest.Mocked<ITrainingRepository>;
  let exerciseRepo: jest.Mocked<IExerciseRepository>;
  let service: TrainingService;

  beforeEach(() => {
    trainingRepo = fakeTrainingRepo();
    exerciseRepo = fakeExerciseRepo();
    service = new TrainingService(trainingRepo, fakeTrainingStateRepo(), exerciseRepo);
  });

  function onlyExisting(...ids: string[]): void {
    exerciseRepo.exists.mockImplementation(async (id) => ids.includes(id));
  }

  it('create responde 400 con los ids que no existen y no guarda nada', async () => {
    onlyExisting('e1');

    await expect(
      service.create({ ...training, exerciseIds: ['e1', 'e9', 'e8'] }, null),
    ).rejects.toMatchObject({ status: 400, message: 'Unknown exercise ids: e9, e8' });
    expect(trainingRepo.create).not.toHaveBeenCalled();
  });

  it('create guarda si todos existen y comprueba cada id una sola vez', async () => {
    onlyExisting('e1', 'e2');
    trainingRepo.create.mockResolvedValue('t1');

    await expect(
      service.create({ ...training, exerciseIds: ['e1', 'e2', 'e1'] }, null),
    ).resolves.toBe('t1');
    expect(exerciseRepo.exists).toHaveBeenCalledTimes(2);
  });

  it('update responde 404 antes de mirar los ejercicios si el entrenamiento no existe', async () => {
    trainingRepo.getById.mockResolvedValue(null);

    await expect(service.update('nope', training, null)).rejects.toMatchObject({ status: 404 });
    expect(exerciseRepo.exists).not.toHaveBeenCalled();
  });

  it('update responde 400 con ejercicios inexistentes y no guarda nada', async () => {
    trainingRepo.getById.mockResolvedValue(training);
    onlyExisting('e1');

    await expect(
      service.update('t1', { exerciseIds: ['e1', 'e9'] }, null),
    ).rejects.toMatchObject({ status: 400, message: 'Unknown exercise ids: e9' });
    expect(trainingRepo.update).not.toHaveBeenCalled();
  });

  // El dueño del entrenamiento es también el viewer con el que se validan sus
  // ejercicios: de ahí sale la regla de mezcla.
  it('un entrenamiento propio valida sus ejercicios con los ojos de su dueño', async () => {
    onlyExisting('e1', 'e2');
    trainingRepo.create.mockResolvedValue('t1');

    await service.create(training, 'u1');

    expect(exerciseRepo.exists).toHaveBeenCalledWith('e1', 'u1');
    expect(trainingRepo.create).toHaveBeenCalledWith(training, 'u1');
  });

  it('uno del catálogo valida sus ejercicios contra el catálogo', async () => {
    onlyExisting('e1', 'e2');
    trainingRepo.create.mockResolvedValue('t1');

    await service.create(training, null);

    expect(exerciseRepo.exists).toHaveBeenCalledWith('e1', null);
  });

  it('un usuario no puede editar un entrenamiento del catálogo por la ruta propia', async () => {
    trainingRepo.getById.mockResolvedValue(training); // sin ownerId = catálogo

    await expect(service.update('t1', { name: 'Pisado' }, 'u1')).rejects.toMatchObject({ status: 404 });
    expect(trainingRepo.update).not.toHaveBeenCalled();
  });

  it('update sin exerciseIds no consulta los ejercicios', async () => {
    trainingRepo.getById.mockResolvedValue(training);

    await service.update('t1', { name: 'Calentamiento largo' }, null);

    expect(exerciseRepo.exists).not.toHaveBeenCalled();
    expect(trainingRepo.update).toHaveBeenCalledWith('t1', { name: 'Calentamiento largo' }, null);
  });
});
