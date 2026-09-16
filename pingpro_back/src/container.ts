/**
 * Composition root: el único sitio del backend que decide qué implementación
 * de cada repositorio se usa y que crea los servicios, una sola vez.
 *
 * Desde el corte, los repositorios son los de Postgres y comparten un solo
 * Pool. Los de Firebase siguen en el repo hasta que la migración esté
 * asentada, pero ya no los usa nadie salvo sus tests de contrato.
 *
 * Firebase Auth se queda: AuthService no tiene repositorio.
 */
import type { Pool } from 'pg';
import { createPool } from './config/postgres';
import type { IExerciseRepository } from './interfaces/repositories/IExerciseRepository';
import type { IModel3DRepository } from './interfaces/repositories/IModel3DRepository';
import type { ITrainingRepository } from './interfaces/repositories/ITrainingRepository';
import type { IUserExerciseStateRepository } from './interfaces/repositories/IUserExerciseStateRepository';
import type { IUserRepository } from './interfaces/repositories/IUserRepository';
import type { IUserTrainingStateRepository } from './interfaces/repositories/IUserTrainingStateRepository';
import { PostgresExerciseRepository } from './repositories/implementations/PostgresExerciseRepository';
import { PostgresModel3DRepository } from './repositories/implementations/PostgresModel3DRepository';
import { PostgresTrainingRepository } from './repositories/implementations/PostgresTrainingRepository';
import { PostgresUserExerciseStateRepository } from './repositories/implementations/PostgresUserExerciseStateRepository';
import { PostgresUserRepository } from './repositories/implementations/PostgresUserRepository';
import { PostgresUserTrainingStateRepository } from './repositories/implementations/PostgresUserTrainingStateRepository';
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

function createPostgresRepositories(pool: Pool): Repositories {
  return {
    exercises: new PostgresExerciseRepository(pool),
    exerciseStates: new PostgresUserExerciseStateRepository(pool),
    trainings: new PostgresTrainingRepository(pool),
    trainingStates: new PostgresUserTrainingStateRepository(pool),
    users: new PostgresUserRepository(pool),
    models3d: new PostgresModel3DRepository(pool),
  };
}

// Un solo pool para toda la API. Crearlo no abre conexiones: se abren al
// primer query.
const pool = createPool();
const repositories = createPostgresRepositories(pool);

export const services = {
  auth: new AuthService(),
  users: new UserService(repositories.users),
  exercises: new ExerciseService(repositories.exercises, repositories.exerciseStates),
  trainings: new TrainingService(repositories.trainings, repositories.trainingStates, repositories.exercises),
  models3d: new Model3DService(repositories.models3d),
};

// Los tests de integración que importan la app tienen que cerrarlo o Jest no
// termina.
export async function closeDatabase(): Promise<void> {
  await pool.end();
}
