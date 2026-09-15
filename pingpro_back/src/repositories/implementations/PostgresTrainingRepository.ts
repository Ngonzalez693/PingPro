/**
 * Implementación en Postgres de ITrainingRepository (tablas trainings y
 * training_exercises).
 *
 * Mismas reglas que PostgresExerciseRepository: solo catálogo, borrado lógico.
 * exerciseIds se devuelve en orden y sin los ejercicios borrados, que así
 * desaparecen de todos los entrenamientos que los usaban.
 */
import type { Pool, PoolClient } from 'pg';
import type { ITraining } from '../../interfaces/models/ITraining';
import type { ITrainingRepository } from '../../interfaces/repositories/ITrainingRepository';
import { withTransaction } from '../../db/transaction';

interface TrainingRow {
  id: string;
  name: string;
  category: string;
  image: string;
  description: string | null;
  duration: number | null;
  exerciseIds: string[];
}

const VISIBLE = 'deleted_at IS NULL AND owner_id IS NULL';

// El LEFT JOIN a exercises con deleted_at IS NULL deja e.id en NULL para los
// ejercicios borrados, y el FILTER los saca de la lista.
const SELECT_TRAININGS = `
  SELECT t.id, t.name, t.category, t.image, t.description, t.duration,
         COALESCE(
           array_agg(te.exercise_id ORDER BY te.position) FILTER (WHERE e.id IS NOT NULL),
           '{}'
         ) AS "exerciseIds"
  FROM trainings t
  LEFT JOIN training_exercises te ON te.training_id = t.id
  LEFT JOIN exercises e ON e.id = te.exercise_id AND e.deleted_at IS NULL
  WHERE t.deleted_at IS NULL AND t.owner_id IS NULL`;

// Los contratos comparan con toEqual: un NULL de la base es un campo ausente.
function toTraining(row: TrainingRow): ITraining {
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    image: row.image,
    ...(row.description === null ? {} : { description: row.description }),
    exerciseIds: row.exerciseIds,
    ...(row.duration === null ? {} : { duration: row.duration }),
  };
}

// Una sola consulta para toda la lista; ORDINALITY da la posición (desde 1).
async function insertExerciseIds(client: PoolClient, trainingId: string, exerciseIds: string[]): Promise<void> {
  await client.query(
    `INSERT INTO training_exercises (training_id, position, exercise_id)
     SELECT $1::text, item.position - 1, item.exercise_id
     FROM unnest($2::text[]) WITH ORDINALITY AS item(exercise_id, position)`,
    [trainingId, exerciseIds],
  );
}

export class PostgresTrainingRepository implements ITrainingRepository {
  constructor(private readonly pool: Pool) {}

  async getAll(): Promise<ITraining[]> {
    const { rows } = await this.pool.query<TrainingRow>(`${SELECT_TRAININGS} GROUP BY t.id`);
    return rows.map(toTraining);
  }

  async getById(id: string): Promise<ITraining | null> {
    const { rows } = await this.pool.query<TrainingRow>(`${SELECT_TRAININGS} AND t.id = $1 GROUP BY t.id`, [id]);
    return rows.length > 0 ? toTraining(rows[0]) : null;
  }

  async create(training: ITraining): Promise<string> {
    return withTransaction(this.pool, async (client) => {
      const { rows } = await client.query<{ id: string }>(
        `INSERT INTO trainings (name, category, image, description, duration)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        [training.name, training.category, training.image, training.description ?? null, training.duration ?? null],
      );
      await insertExerciseIds(client, rows[0].id, training.exerciseIds);
      return rows[0].id;
    });
  }

  // COALESCE: lo que no viene en el patch conserva su valor, como update() de
  // Firestore. Si llega exerciseIds, se sustituye la lista entera.
  async update(id: string, training: Partial<ITraining>): Promise<void> {
    await withTransaction(this.pool, async (client) => {
      const { rowCount } = await client.query(
        `UPDATE trainings
         SET name        = COALESCE($2, name),
             category    = COALESCE($3, category),
             image       = COALESCE($4, image),
             description = COALESCE($5, description),
             duration    = COALESCE($6, duration),
             updated_at  = now()
         WHERE id = $1 AND ${VISIBLE}`,
        [
          id,
          training.name ?? null,
          training.category ?? null,
          training.image ?? null,
          training.description ?? null,
          training.duration ?? null,
        ],
      );
      if (rowCount === 0) {
        throw new Error(`Training not found: ${id}`);
      }
      if (training.exerciseIds) {
        await client.query('DELETE FROM training_exercises WHERE training_id = $1', [id]);
        await insertExerciseIds(client, id, training.exerciseIds);
      }
    });
  }

  async delete(id: string): Promise<void> {
    await this.pool.query(`UPDATE trainings SET deleted_at = now() WHERE id = $1 AND ${VISIBLE}`, [id]);
  }

  async exists(id: string): Promise<boolean> {
    const { rows } = await this.pool.query<{ found: boolean }>(
      `SELECT EXISTS (SELECT 1 FROM trainings WHERE id = $1 AND ${VISIBLE}) AS found`,
      [id],
    );
    return rows[0].found;
  }
}
