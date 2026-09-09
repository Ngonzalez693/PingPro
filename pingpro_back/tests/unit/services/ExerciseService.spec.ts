import { ExerciseService } from '../../../src/services/ExerciseService';
import { FirebaseExerciseRepository } from '../../../src/repositories/implementations/FirebaseExerciseRepository';

jest.mock('../../../src/repositories/implementations/FirebaseExerciseRepository');

describe('ExerciseService', () => {
  let service: ExerciseService;

  beforeEach(() => {
    const repoMock = new FirebaseExerciseRepository() as jest.Mocked<FirebaseExerciseRepository>;
    service = new ExerciseService();
  });

  it('create lanza error si falta name', async () => {
    await expect(service.create({ name: '', sequence: [] }))
      .rejects.toThrow('Name is required');
  });
});