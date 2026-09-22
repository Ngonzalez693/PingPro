/**
 * Implementación en Postgres de IExerciseRepository (tablas exercises y
 * exercise_steps).
 *
 * Qué se ve depende de quién mira: el catálogo (owner_id IS NULL) más los
 * ejercicios privados del propio usuario. Las escrituras de esta clase siguen
 * siendo solo de catálogo; las de los ejercicios privados van aparte.
 *
 * Borrar es lógico (deleted_at): el ejercicio deja de verse, pero su historial
 * y sus estados se conservan.
 */
import type { Pool, PoolClient } from 'pg';
import type { IExercise } from '../../interfaces/models/IExercise';
import type { ISequenceStep } from '../../interfaces/models/ISequenceStep';
import type { IExerciseRepository } from '../../interfaces/repositories/IExerciseRepository';
import { withTransaction } from '../../db/transaction';

interface ExerciseRow {
  id: string;
  owner_id: string | null;
  name: string;
  category: string;
  image: string;
  description: string | null;
  sequence: ISequenceStep[];
}

// Filas de un dueño concreto, que va en el último parámetro: null = catálogo,
// un uid = lo privado de ese usuario.
//
// IS NOT DISTINCT FROM y no `=` porque compara bien contra NULL: con null
// coincide con las filas de catálogo, y con un uid solo con las suyas. Así una
// escritura nunca alcanza filas de otro dueño.
const OWNED_BY = 'deleted_at IS NULL AND owner_id IS NOT DISTINCT FROM';

// Catálogo + lo privado de quien mira, que va en $1.
//
// Con $1 = NULL no hace falta un caso aparte: en SQL `owner_id = NULL` nunca
// es cierto (da NULL), así que la condición se queda en `owner_id IS NULL` y
// la consulta devuelve solo el catálogo.
const VISIBLE_TO_VIEWER = 'deleted_at IS NULL AND (owner_id IS NULL OR owner_id = $1)';

// La secuencia llega en la misma consulta, ya ordenada por position.
const SELECT_EXERCISES = `
  SELECT e.id, e.owner_id, e.name, e.category, e.image, e.description,
         COALESCE(
           json_agg(
             json_build_object(
               'hit', s.hit, 'rotation', s.rotation, 'zone', s.zone,
               'direction', s.direction, 'side', s.side, 'ownZone', s.own_zone
             ) ORDER BY s.position
           ) FILTER (WHERE s.exercise_id IS NOT NULL),
           '[]'
         ) AS sequence
  FROM exercises e
  LEFT JOIN exercise_steps s ON s.exercise_id = e.id
  WHERE e.deleted_at IS NULL AND (e.owner_id IS NULL OR e.owner_id = $1)`;

// Los contratos comparan con toEqual: un NULL de la base es un campo ausente.
// Por eso un ejercicio del catálogo sale sin ownerId, igual que antes de que
// existieran los privados.
function toExercise(row: ExerciseRow): IExercise {
  return {
    id: row.id,
    ...(row.owner_id === null ? {} : { ownerId: row.owner_id }),
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
    `INSERT INTO exercise_steps (exercise_id, position, hit, rotation, zone, direction, side, own_zone)
     SELECT $1::text, step.position - 1, step.hit, step.rotation, step.zone, step.direction, step.side, step.own_zone
     FROM unnest($2::smallint[], $3::smallint[], $4::smallint[], $5::smallint[], $6::smallint[], $7::smallint[])
          WITH ORDINALITY AS step(hit, rotation, zone, direction, side, own_zone, position)`,
    [
      exerciseId,
      steps.map((step) => step.hit),
      steps.map((step) => step.rotation),
      steps.map((step) => step.zone),
      steps.map((step) => step.direction),
      steps.map((step) => step.side),
      steps.map((step) => step.ownZone),
    ],
  );
}

export class PostgresExerciseRepository implements IExerciseRepository {
  constructor(private readonly pool: Pool) {}

  async getAll(viewerId: string | null): Promise<IExercise[]> {
    const { rows } = await this.pool.query<ExerciseRow>(`${SELECT_EXERCISES} GROUP BY e.id`, [viewerId]);
    return rows.map(toExercise);
  }

  async getById(id: string, viewerId: string | null): Promise<IExercise | null> {
    const { rows } = await this.pool.query<ExerciseRow>(
      `${SELECT_EXERCISES} AND e.id = $2 GROUP BY e.id`,
      [viewerId, id],
    );
    return rows.length > 0 ? toExercise(rows[0]) : null;
  }

  // ownerId null crea catálogo; con un uid, un ejercicio privado de ese usuario.
  async create(exercise: IExercise, ownerId: string | null): Promise<string> {
    return withTransaction(this.pool, async (client) => {
      const { rows } = await client.query<{ id: string }>(
        `INSERT INTO exercises (owner_id, name, category, image, description)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        [ownerId, exercise.name, exercise.category, exercise.image, exercise.description ?? null],
      );
      await insertSteps(client, rows[0].id, exercise.sequence);
      return rows[0].id;
    });
  }

  // COALESCE: lo que no viene en el patch conserva su valor, como update() de
  // Firestore. Si llega sequence, se sustituye entera.
  //
  // El dueño forma parte del WHERE: un id de otro dueño no actualiza ninguna
  // fila y sale por el mismo camino que un id inexistente.
  async update(id: string, exercise: Partial<IExercise>, ownerId: string | null): Promise<void> {
    await withTransaction(this.pool, async (client) => {
      const { rowCount } = await client.query(
        `UPDATE exercises
         SET name        = COALESCE($2, name),
             category    = COALESCE($3, category),
             image       = COALESCE($4, image),
             description = COALESCE($5, description),
             updated_at  = now()
         WHERE id = $1 AND ${OWNED_BY} $6`,
        [
          id,
          exercise.name ?? null,
          exercise.category ?? null,
          exercise.image ?? null,
          exercise.description ?? null,
          ownerId,
        ],
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

  async delete(id: string, ownerId: string | null): Promise<void> {
    await this.pool.query(
      `UPDATE exercises SET deleted_at = now() WHERE id = $1 AND ${OWNED_BY} $2`,
      [id, ownerId],
    );
  }

  async exists(id: string, viewerId: string | null): Promise<boolean> {
    const { rows } = await this.pool.query<{ found: boolean }>(
      `SELECT EXISTS (SELECT 1 FROM exercises WHERE id = $2 AND ${VISIBLE_TO_VIEWER}) AS found`,
      [viewerId, id],
    );
    return rows[0].found;
  }
}
