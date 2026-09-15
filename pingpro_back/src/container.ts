/**
 * Composition root: el único sitio del backend que decide qué implementación
 * de cada repositorio se usa y que crea los servicios, una sola vez.
 *
 * Los servicios solo conocen las interfaces. Pasar a Supabase consistirá en
 * escribir createSupabaseRepositories() y usarla aquí en lugar de la de
 * Firebase: el tipo Repositories obliga a que devuelva lo mismo.
 */
import type { IExerciseRepository } from './interfaces/repositories/IExerciseRepository';
import type { IModel3DRepository } from './interfaces/repositories/IModel3DRepository';
import type { ITrainingRepository } from './interfaces/repositories/ITrainingRepository';
import type { IUserExerciseStateRepository } from './interfaces/repositories/IUserExerciseStateRepository';
import type { IUserRepository } from './interfaces/repositories/IUserRepository';
import type { IUserTrainingStateRepository } from './interfaces/repositories/IUserTrainingStateRepository';
import { FirebaseExerciseRepository } from './repositories/implementations/FirebaseExerciseRepository';
import FirebaseModel3DRepository from './repositories/implementations/FirebaseModel3DRepository';
import { FirebaseTrainingRepository } from './repositories/implementations/FirebaseTrainingRepository';
import FirebaseUserExerciseStateRepository from './repositories/implementations/FirebaseUserExerciseStateRepository';
import { FirebaseUserRepository } from './repositories/implementations/FirebaseUserRepository';
import FirebaseUserTrainingStateRepository from './repositories/implementations/FirebaseUserTrainingStateRepository';
import { AuthService } from './services/AuthService';
import { ExerciseService } from './services/ExerciseService';
import Model3DService from './services/Model3DService';
import { TrainingService } from './services/TrainingService';
import { UserService } from './services/UserService';

interface Repositories {
  exercises: IExerciseRepository;
  exerciseStates: IUserExerciseStateRepository;
  trainings: ITrainingRepository;
  trainingStates: IUserTrainingStateRepository;
  users: IUserRepository;
  models3d: IModel3DRepository;
}

function createFirebaseRepositories(): Repositories {
  return {
    exercises: new FirebaseExerciseRepository(),
    exerciseStates: new FirebaseUserExerciseStateRepository(),
    trainings: new FirebaseTrainingRepository(),
    trainingStates: new FirebaseUserTrainingStateRepository(),
    users: new FirebaseUserRepository(),
    models3d: new FirebaseModel3DRepository(),
  };
}

const repositories = createFirebaseRepositories();

export const services = {
  // Firebase Auth se queda en la migración: AuthService no tiene repositorio.
  auth: new AuthService(),
  users: new UserService(repositories.users),
  exercises: new ExerciseService(repositories.exercises, repositories.exerciseStates),
  trainings: new TrainingService(repositories.trainings, repositories.trainingStates, repositories.exercises),
  models3d: new Model3DService(repositories.models3d),
};
