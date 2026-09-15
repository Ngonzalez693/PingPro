/**
 * Implementación en Postgres de IExerciseRepository (tablas exercises y
 * exercise_steps).
 *
 * Solo ve el catálogo (owner_id IS NULL): los ejercicios privados llegan con su
 * propio sub-proyecto. Borrar es lógico (deleted_at): el ejercicio deja de
 * verse, pero su historial y sus estados se conservan.
 */
import type { Pool, PoolClient } from 'pg';
import type { IExercise } from '../../interfaces/models/IExercise';
import type { ISequenceStep } from '../../interfaces/models/ISequenceStep';
import type { IExerciseRepository } from '../../interfaces/repositories/IExerciseRepository';
import { withTransaction } from '../../db/transaction';

interface ExerciseRow {
  id: string;
  name: string;
  category: string;
  image: string;
  description: string | null;
  sequence: ISequenceStep[];
}

const VISIBLE = 'deleted_at IS NULL AND owner_id IS NULL';

// La secuencia llega en la misma consulta, ya ordenada por position.
const SELECT_EXERCISES = `
  SELECT e.id, e.name, e.category, e.image, e.description,
         COALESCE(
           json_agg(
             json_build_object(
               'hit', s.hit, 'rotation', s.rotation, 'zone', s.zone,
               'direction', s.direction, 'side', s.side
             ) ORDER BY s.position
           ) FILTER (WHERE s.exercise_id IS NOT NULL),
           '[]'
         ) AS sequence
  FROM exercises e
  LEFT JOIN exercise_steps s ON s.exercise_id = e.id
  WHERE e.deleted_at IS NULL AND e.owner_id IS NULL`;

// Los contratos comparan con toEqual: un NULL de la base es un campo ausente.
function toExercise(row: ExerciseRow): IExercise {
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    image: row.image,
    ...(row.description === null ? {} : { description: row.description }),
    sequence: row.sequence,
  };
}

// Una sola consulta para todos los pasos; ORDINALITY da la posición (desde 1).
async function insertSteps(client: PoolClient, exerciseId: string, steps: ISequenceStep[]): Promise<void> {
  await client.query(
    `INSERT INTO exercise_steps (exercise_id, position, hit, rotation, zone, direction, side)
     SELECT $1::text, step.position - 1, step.hit, step.rotation, step.zone, step.direction, step.side
     FROM unnest($2::smallint[], $3::smallint[], $4::smallint[], $5::smallint[], $6::smallint[])
          WITH ORDINALITY AS step(hit, rotation, zone, direction, side, position)`,
    [
      exerciseId,
      steps.map((step) => step.hit),
      steps.map((step) => step.rotation),
      steps.map((step) => step.zone),
      steps.map((step) => step.direction),
      steps.map((step) => step.side),
    ],
  );
}

export class PostgresExerciseRepository implements IExerciseRepository {
  constructor(private readonly pool: Pool) {}

  async getAll(): Promise<IExercise[]> {
    const { rows } = await this.pool.query<ExerciseRow>(`${SELECT_EXERCISES} GROUP BY e.id`);
    return rows.map(toExercise);
  }

  async getById(id: string): Promise<IExercise | null> {
    const { rows } = await this.pool.query<ExerciseRow>(`${SELECT_EXERCISES} AND e.id = $1 GROUP BY e.id`, [id]);
    return rows.length > 0 ? toExercise(rows[0]) : null;
  }

  async create(exercise: IExercise): Promise<string> {
    return withTransaction(this.pool, async (client) => {
      const { rows } = await client.query<{ id: string }>(
        `INSERT INTO exercises (name, category, image, description)
         VALUES ($1, $2, $3, $4)
         RETURNING id`,
        [exercise.name, exercise.category, exercise.image, exercise.description ?? null],
      );
      await insertSteps(client, rows[0].id, exercise.sequence);
      return rows[0].id;
    });
  }

  // COALESCE: lo que no viene en el patch conserva su valor, como update() de
  // Firestore. Si llega sequence, se sustituye entera.
  async update(id: string, exercise: Partial<IExercise>): Promise<void> {
    await withTransaction(this.pool, async (client) => {
      const { rowCount } = await client.query(
        `UPDATE exercises
         SET name        = COALESCE($2, name),
             category    = COALESCE($3, category),
             image       = COALESCE($4, image),
             description = COALESCE($5, description),
             updated_at  = now()
         WHERE id = $1 AND ${VISIBLE}`,
        [id, exercise.name ?? null, exercise.category ?? null, exercise.image ?? null, exercise.description ?? null],
      );
      if (rowCount === 0) {
        throw new Error(`Exercise not found: ${id}`);
      }
      if (exercise.sequence) {
        await client.query('DELETE FROM exercise_steps WHERE exercise_id = $1', [id]);
        await insertSteps(client, id, exercise.sequence);
      }
    });
  }

  async delete(id: string): Promise<void> {
    await this.pool.query(`UPDATE exercises SET deleted_at = now() WHERE id = $1 AND ${VISIBLE}`, [id]);
  }

  async exists(id: string): Promise<boolean> {
    const { rows } = await this.pool.query<{ found: boolean }>(
      `SELECT EXISTS (SELECT 1 FROM exercises WHERE id = $1 AND ${VISIBLE}) AS found`,
      [id],
    );
    return rows[0].found;
  }
}
