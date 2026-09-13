import { db } from '../../../src/config/firebase';
import { FirebaseExerciseRepository } from '../../../src/repositories/implementations/FirebaseExerciseRepository';
import { FirebaseTrainingRepository } from '../../../src/repositories/implementations/FirebaseTrainingRepository';
import FirebaseModel3DRepository from '../../../src/repositories/implementations/FirebaseModel3DRepository';
import { catalogRepositoryContract } from '../../contracts/catalogRepository.contract';
import { model3dRepositoryContract } from '../../contracts/model3dRepository.contract';
import { exerciseFixtures, trainingFixtures } from '../../contracts/fixtures';
import { clearFirestore, closeFirebaseApp } from '../helpers/emulators';

// Enlace de los contratos con las implementaciones de Firebase, sobre el
// emulador. El de Supabase será un archivo hermano que llame a las mismas
// funciones con sus propias clases.

catalogRepositoryContract(
  'FirebaseExerciseRepository',
  { createRepository: () => new FirebaseExerciseRepository(), reset: clearFirestore },
  exerciseFixtures,
);

catalogRepositoryContract(
  'FirebaseTrainingRepository',
  { createRepository: () => new FirebaseTrainingRepository(), reset: clearFirestore },
  trainingFixtures,
);

model3dRepositoryContract('FirebaseModel3DRepository', {
  createRepository: () => new FirebaseModel3DRepository(),
  reset: clearFirestore,
  // Como en producción, el id es el del documento y no un campo más.
  seed: async (models) => {
    await Promise.all(
      models.map(({ id, ...data }) => db.collection('model3d').doc(id).set(data)),
    );
  },
});

afterAll(closeFirebaseApp);
