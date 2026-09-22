/**
 * Parte pura de la migración de Firestore a Postgres.
 *
 * Recibe lo leído de Firestore (con las fechas ya convertidas a Date) y
 * devuelve las filas a insertar y la lista de problemas, sin tocar ninguna
 * base de datos. Ejercicios y entrenamientos se validan con los mismos
 * esquemas Joi que la API: entra lo mismo que la API aceptaría hoy.
 *
 * Tipos de problema:
 *   blocking  → impide --apply: hay que corregir el dato o ampliar las reglas.
 *   discarded → se omite y se lista (referencias a cosas que ya no existen).
 *   warning   → se migra igual, pero conviene saberlo.
 *
 * Los problemas solo nombran rutas e ids, nunca emails.
 */
import type { IExercise } from '../interfaces/models/IExercise';
import type { ITraining } from '../interfaces/models/ITraining';
import { exerciseSchema } from '../utils/exercise.validator';
import { trainingSchema } from '../utils/training.validator';

export type FirestoreData = Record<string, unknown>;

export interface FirestoreDoc {
  id: string;
  data: FirestoreData;
}

// Documento de users/{uid}/exerciseStates o trainingStates: el uid sale de la
// ruta, no del documento.
export interface StateDoc extends FirestoreDoc {
  userId: string;
}

export interface AuthUser {
  uid: string;
  createdAt: Date;
}

export interface FirestoreSnapshot {
  users: FirestoreDoc[];
  exercises: FirestoreDoc[];
  trainings: FirestoreDoc[];
  models3d: FirestoreDoc[];
  exerciseStates: StateDoc[];
  trainingStates: StateDoc[];
  authUsers: AuthUser[];
}

// Claves = tablas y columnas de 0001: el cargador inserta sin mapear.
export interface MigrationRows {
  users: Array<{
    id: string;
    email: string;
    display_name: string | null;
    photo_url: string | null;
    roles: string[] | null;
    created_at: Date;
    updated_at: Date;
  }>;
  exercises: Array<{
    id: string;
    name: string;
    category: string;
    image: string;
    description: string | null;
    created_at: Date;
    updated_at: Date;
  }>;
  exercise_steps: Array<{
    exercise_id: string;
    position: number;
    hit: number;
    rotation: number;
    zone: number;
    direction: number;
    side: number;
    own_zone: number;
  }>;
  trainings: Array<{
    id: string;
    name: string;
    category: string;
    image: string;
    description: string | null;
    duration: number | null;
    created_at: Date;
    updated_at: Date;
  }>;
  training_exercises: Array<{ training_id: string; position: number; exercise_id: string }>;
  models_3d: Array<{ id: string; name: string; url: string; created_at: Date; updated_at: Date }>;
  user_exercise_states: Array<{ user_id: string; exercise_id: string; is_favorite: boolean | null; updated_at: Date }>;
  exercise_completions: Array<{ user_id: string; exercise_id: string; completed_at: Date }>;
  user_training_states: Array<{ user_id: string; training_id: string; updated_at: Date }>;
  training_completions: Array<{ user_id: string; training_id: string; completed_at: Date }>;
}

export type ProblemKind = 'blocking' | 'discarded' | 'warning';

export interface Problem {
  kind: ProblemKind;
  path: string;
  message: string;
}

export interface MigrationPlan {
  rows: MigrationRows;
  problems: Problem[];
}

type Report = (kind: ProblemKind, path: string, message: string) => void;

const PER_USER_EXERCISE_FIELDS = ['isFavorite', 'completedAt'];

function text(data: FirestoreData, field: string): string | undefined {
  const value = data[field];
  return typeof value === 'string' ? value : undefined;
}

function date(data: FirestoreData, field: string): Date | undefined {
  const value = data[field];
  return value instanceof Date ? value : undefined;
}

function stringList(value: unknown): string[] | null {
  return Array.isArray(value) && value.every((item): item is string => typeof item === 'string') ? value : null;
}

// Los esquemas Joi rechazan claves desconocidas: se valida solo lo que migra.
function pick(data: FirestoreData, fields: string[]): FirestoreData {
  return Object.fromEntries(fields.filter((field) => data[field] !== undefined).map((field) => [field, data[field]]));
}

function emptyRows(): MigrationRows {
  return {
    users: [],
    exercises: [],
    exercise_steps: [],
    trainings: [],
    training_exercises: [],
    models_3d: [],
    user_exercise_states: [],
    exercise_completions: [],
    user_training_states: [],
    training_completions: [],
  };
}

function planUsers(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  const authCreatedAt = new Map(snapshot.authUsers.map((user) => [user.uid, user.createdAt]));
  for (const { id, data } of snapshot.users) {
    const email = text(data, 'email');
    if (!email) {
      report('blocking', `users/${id}`, 'has no email');
      continue;
    }
    const createdAt = date(data, 'createdAt') ?? authCreatedAt.get(id) ?? now;
    rows.users.push({
      id,
      email,
      display_name: text(data, 'displayName') ?? null,
      photo_url: text(data, 'photoURL') ?? null,
      roles: stringList(data.roles),
      created_at: createdAt,
      updated_at: date(data, 'updatedAt') ?? createdAt,
    });
  }

  const profiles = new Set(snapshot.users.map((user) => user.id));
  for (const { uid } of snapshot.authUsers) {
    if (!profiles.has(uid)) {
      report('warning', `auth/${uid}`, 'has no profile document: the app fails for this account');
    }
  }
}

function planExercises(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  for (const { id, data } of snapshot.exercises) {
    const path = `exercises/${id}`;
    const stray = PER_USER_EXERCISE_FIELDS.filter((field) => field in data);
    if (stray.length > 0) {
      report('warning', path, `ignores per-user fields: ${stray.join(', ')}`);
    }

    const { error, value } = exerciseSchema.validate(
      pick(data, ['name', 'category', 'image', 'description', 'sequence']),
      { convert: false },
    );
    if (error) {
      report('blocking', path, error.message);
      continue;
    }

    const exercise: IExercise = value;
    const createdAt = date(data, 'createdAt') ?? now;
    rows.exercises.push({
      id,
      name: exercise.name,
      category: exercise.category,
      image: exercise.image,
      description: exercise.description ?? null,
      created_at: createdAt,
      updated_at: date(data, 'updatedAt') ?? createdAt,
    });
    // Columnas snake_case explícitas: load.ts usa las claves de la fila como
    // nombres de columna, y el paso viene con ownZone en camelCase.
    exercise.sequence.forEach((step, position) =>
      rows.exercise_steps.push({
        exercise_id: id,
        position,
        hit: step.hit,
        rotation: step.rotation,
        zone: step.zone,
        direction: step.direction,
        side: step.side,
        own_zone: step.ownZone,
      }),
    );
  }
}

function planTrainings(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  const exerciseIds = new Set(rows.exercises.map((exercise) => exercise.id));
  for (const { id, data } of snapshot.trainings) {
    const path = `trainings/${id}`;
    const { error, value } = trainingSchema.validate(
      pick(data, ['name', 'category', 'image', 'description', 'exerciseIds', 'duration']),
      { convert: false },
    );
    if (error) {
      report('blocking', path, error.message);
      continue;
    }

    const training: ITraining = value;
    const kept: string[] = [];
    for (const exerciseId of training.exerciseIds) {
      if (exerciseIds.has(exerciseId)) {
        kept.push(exerciseId);
      } else {
        report('discarded', path, `drops unknown exercise ${exerciseId}`);
      }
    }
    if (kept.length === 0) {
      report('warning', path, 'has no exercises left');
    }

    const createdAt = date(data, 'createdAt') ?? now;
    rows.trainings.push({
      id,
      name: training.name,
      category: training.category,
      image: training.image,
      description: training.description ?? null,
      duration: training.duration ?? null,
      created_at: createdAt,
      updated_at: date(data, 'updatedAt') ?? createdAt,
    });
    kept.forEach((exerciseId, position) =>
      rows.training_exercises.push({ training_id: id, position, exercise_id: exerciseId }),
    );
  }
}

function planModels3d(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  const names = new Set<string>();
  for (const { id, data } of snapshot.models3d) {
    const path = `model3d/${id}`;
    const name = text(data, 'name');
    const url = text(data, 'url');
    if (!name || !url) {
      report('blocking', path, 'needs a name and a url');
      continue;
    }
    // name es la llave del mapper de animaciones: repetido, uno taparía al otro.
    if (names.has(name)) {
      report('blocking', path, `repeats the name "${name}"`);
      continue;
    }
    names.add(name);
    const createdAt = date(data, 'createdAt') ?? now;
    rows.models_3d.push({ id, name, url, created_at: createdAt, updated_at: date(data, 'updatedAt') ?? createdAt });
  }
}

function planExerciseStates(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  const users = new Set(rows.users.map((user) => user.id));
  const exercises = new Set(rows.exercises.map((exercise) => exercise.id));
  for (const { id: exerciseId, userId, data } of snapshot.exerciseStates) {
    const path = `users/${userId}/exerciseStates/${exerciseId}`;
    if (!users.has(userId) || !exercises.has(exerciseId)) {
      report('discarded', path, 'points to a user or exercise that does not exist');
      continue;
    }
    const completedAt = date(data, 'completedAt');
    const isFavorite = data.isFavorite;
    rows.user_exercise_states.push({
      user_id: userId,
      exercise_id: exerciseId,
      is_favorite: typeof isFavorite === 'boolean' ? isFavorite : null,
      updated_at: date(data, 'updatedAt') ?? completedAt ?? now,
    });
    if (completedAt) {
      rows.exercise_completions.push({ user_id: userId, exercise_id: exerciseId, completed_at: completedAt });
    }
  }
}

function planTrainingStates(snapshot: FirestoreSnapshot, now: Date, rows: MigrationRows, report: Report): void {
  const users = new Set(rows.users.map((user) => user.id));
  const trainings = new Set(rows.trainings.map((training) => training.id));
  for (const { id: trainingId, userId, data } of snapshot.trainingStates) {
    const path = `users/${userId}/trainingStates/${trainingId}`;
    if (!users.has(userId) || !trainings.has(trainingId)) {
      report('discarded', path, 'points to a user or training that does not exist');
      continue;
    }
    const completedAt = date(data, 'completedAt');
    rows.user_training_states.push({
      user_id: userId,
      training_id: trainingId,
      updated_at: date(data, 'updatedAt') ?? completedAt ?? now,
    });
    if (completedAt) {
      rows.training_completions.push({ user_id: userId, training_id: trainingId, completed_at: completedAt });
    }
  }
}

// El orden importa: entrenamientos y estados solo aceptan referencias a filas
// que ya pasaron la validación.
export function buildMigrationPlan(snapshot: FirestoreSnapshot, now: Date): MigrationPlan {
  const rows = emptyRows();
  const problems: Problem[] = [];
  const report: Report = (kind, path, message) => problems.push({ kind, path, message });

  planUsers(snapshot, now, rows, report);
  planExercises(snapshot, now, rows, report);
  planTrainings(snapshot, now, rows, report);
  planModels3d(snapshot, now, rows, report);
  planExerciseStates(snapshot, now, rows, report);
  planTrainingStates(snapshot, now, rows, report);

  return { rows, problems };
}
