/**
 * Implementación en Postgres de IStatsRepository: tres consultas
 * independientes, en paralelo.
 *
 * Las finalizaciones NO filtran deleted_at: si un ejercicio o entrenamiento se
 * borró después, lo entrenado sigue contando. "Creados" sí lo filtra (decisión
 * del spec) y solo mira lo propio: del catálogo no se guarda quién lo creó.
 */
import type { Pool } from 'pg';
import type {
  CreatedKind,
  ICreatedEvent,
  IExerciseCompletionEvent,
  IStatsEvents,
  ITrainingCompletionEvent,
} from '../../interfaces/models/IStatsEvents';
import type { IStatsRepository } from '../../interfaces/repositories/IStatsRepository';

interface ExerciseCompletionRow {
  exercise_id: string;
  completed_at: Date;
  session: number | null;
  category: string;
  hits: number[];
  rotations: number[];
  deleted: boolean;
}

interface TrainingCompletionRow {
  training_id: string;
  completed_at: Date;
  session: number | null;
  duration: number | null;
}

interface CreatedRow {
  kind: CreatedKind;
  id: string;
  created_at: Date;
}

// Los códigos se agregan por ejercicio una vez y no por finalización: un
// ejercicio repetido 20 veces no repite el trabajo.
const SELECT_EXERCISE_COMPLETIONS = `
  WITH codes AS (
    SELECT exercise_id,
           array_agg(DISTINCT hit ORDER BY hit) AS hits,
           array_agg(DISTINCT rotation ORDER BY rotation) AS rotations
    FROM exercise_steps
    GROUP BY exercise_id
  )
  SELECT c.exercise_id, c.completed_at, c.session, e.category,
         COALESCE(codes.hits, '{}'::smallint[]) AS hits,
         COALESCE(codes.rotations, '{}'::smallint[]) AS rotations,
         e.deleted_at IS NOT NULL AS deleted
  FROM exercise_completions c
  JOIN exercises e ON e.id = c.exercise_id
  LEFT JOIN codes ON codes.exercise_id = c.exercise_id
  WHERE c.user_id = $1 AND c.completed_at >= $2
  ORDER BY c.completed_at, c.id`;

const SELECT_TRAINING_COMPLETIONS = `
  SELECT c.training_id, c.completed_at, c.session, t.duration
  FROM training_completions c
  JOIN trainings t ON t.id = c.training_id
  WHERE c.user_id = $1 AND c.completed_at >= $2
  ORDER BY c.completed_at, c.id`;

const SELECT_CREATED = `
  SELECT 'exercise' AS kind, id, created_at
  FROM exercises
  WHERE owner_id = $1 AND deleted_at IS NULL AND created_at >= $2
  UNION ALL
  SELECT 'training' AS kind, id, created_at
  FROM trainings
  WHERE owner_id = $1 AND deleted_at IS NULL AND created_at >= $2
  ORDER BY created_at, kind, id`;

function toExerciseCompletion(row: ExerciseCompletionRow): IExerciseCompletionEvent {
  return {
    exerciseId: row.exercise_id,
    completedAt: row.completed_at,
    session: row.session,
    category: row.category,
    hits: row.hits,
    rotations: row.rotations,
    deleted: row.deleted,
  };
}

function toTrainingCompletion(row: TrainingCompletionRow): ITrainingCompletionEvent {
  return {
    trainingId: row.training_id,
    completedAt: row.completed_at,
    session: row.session,
    duration: row.duration,
  };
}

function toCreated(row: CreatedRow): ICreatedEvent {
  return { kind: row.kind, id: row.id, createdAt: row.created_at };
}

export class PostgresStatsRepository implements IStatsRepository {
  constructor(private readonly pool: Pool) {}

  async getEvents(userId: string, from: Date): Promise<IStatsEvents> {
    const params = [userId, from];
    const [exercises, trainings, created] = await Promise.all([
      this.pool.query<ExerciseCompletionRow>(SELECT_EXERCISE_COMPLETIONS, params),
      this.pool.query<TrainingCompletionRow>(SELECT_TRAINING_COMPLETIONS, params),
      this.pool.query<CreatedRow>(SELECT_CREATED, params),
    ]);
    return {
      exerciseCompletions: exercises.rows.map(toExerciseCompletion),
      trainingCompletions: trainings.rows.map(toTrainingCompletion),
      created: created.rows.map(toCreated),
    };
  }
}
