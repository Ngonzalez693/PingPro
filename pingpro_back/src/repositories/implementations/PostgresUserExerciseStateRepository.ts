/**
 * Implementación en Postgres de IUserExerciseStateRepository.
 *
 * Dos tablas: user_exercise_states guarda el favorito y cuándo se tocó el
 * estado por última vez; exercise_completions guarda una fila por cada vez que
 * se completa (el historial de las estadísticas). El completedAt que ve la API
 * es la finalización más reciente, y setCompleted(false) deshace esa última.
 *
 * Las fechas salen del reloj de Node, como en Firestore.
 */
import type { Pool, PoolClient } from 'pg';
import type { IUserExerciseState } from '../../interfaces/models/IUserExerciseState';
import type { IUserExerciseStateRepository } from '../../interfaces/repositories/IUserExerciseStateRepository';
import { withTransaction } from '../../db/transaction';

interface StateRow {
  user_id: string;
  exercise_id: string;
  is_favorite: boolean | null;
  updated_at: Date;
  completed_at: Date | null;
}

const SELECT_STATES = `
  SELECT s.user_id, s.exercise_id, s.is_favorite, s.updated_at,
         (SELECT max(c.completed_at)
          FROM exercise_completions c
          WHERE c.user_id = s.user_id AND c.exercise_id = s.exercise_id) AS completed_at
  FROM user_exercise_states s
  WHERE s.user_id = $1`;

// Como en Firestore: completedAt nunca escrito sale null, isFavorite nunca
// escrito no aparece.
function toState(row: StateRow): IUserExerciseState {
  return {
    userId: row.user_id,
    exerciseId: row.exercise_id,
    ...(row.is_favorite === null ? {} : { isFavorite: row.is_favorite }),
    completedAt: row.completed_at,
    updatedAt: row.updated_at,
  };
}

// Crea el estado si no existe y marca cuándo se tocó, sin pisar el favorito.
async function touchState(client: PoolClient, userId: string, exerciseId: string, now: Date): Promise<void> {
  await client.query(
    `INSERT INTO user_exercise_states (user_id, exercise_id, updated_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, exercise_id) DO UPDATE SET updated_at = EXCLUDED.updated_at`,
    [userId, exerciseId, now],
  );
}

export class PostgresUserExerciseStateRepository implements IUserExerciseStateRepository {
  constructor(private readonly pool: Pool) {}

  async setFavorite(userId: string, exerciseId: string, isFavorite: boolean): Promise<IUserExerciseState> {
    await this.pool.query(
      `INSERT INTO user_exercise_states (user_id, exercise_id, is_favorite, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, exercise_id)
       DO UPDATE SET is_favorite = EXCLUDED.is_favorite, updated_at = EXCLUDED.updated_at`,
      [userId, exerciseId, isFavorite, new Date()],
    );
    return this.requireState(userId, exerciseId);
  }

  // true añade una fila al historial; false borra la más reciente (deshacer).
  async setCompleted(
    userId: string,
    exerciseId: string,
    completed: boolean,
    session: number | null = null,
  ): Promise<IUserExerciseState> {
    const now = new Date();
    await withTransaction(this.pool, async (client) => {
      if (completed) {
        await client.query(
          'INSERT INTO exercise_completions (user_id, exercise_id, completed_at, session) VALUES ($1, $2, $3, $4)',
          [userId, exerciseId, now, session],
        );
      } else {
        await client.query(
          `DELETE FROM exercise_completions
           WHERE id = (SELECT id FROM exercise_completions
                       WHERE user_id = $1 AND exercise_id = $2
                       ORDER BY completed_at DESC, id DESC
                       LIMIT 1)`,
          [userId, exerciseId],
        );
      }
      await touchState(client, userId, exerciseId, now);
    });
    return this.requireState(userId, exerciseId);
  }

  async getState(userId: string, exerciseId: string): Promise<IUserExerciseState | null> {
    const { rows } = await this.pool.query<StateRow>(`${SELECT_STATES} AND s.exercise_id = $2`, [userId, exerciseId]);
    return rows.length > 0 ? toState(rows[0]) : null;
  }

  async getAllStates(userId: string): Promise<IUserExerciseState[]> {
    const { rows } = await this.pool.query<StateRow>(SELECT_STATES, [userId]);
    return rows.map(toState);
  }

  // Después de escribir, el estado existe siempre; el error solo cubre un fallo
  // imposible y le da un mensaje claro.
  private async requireState(userId: string, exerciseId: string): Promise<IUserExerciseState> {
    const state = await this.getState(userId, exerciseId);
    if (!state) {
      throw new Error(`Exercise state not found after writing: ${userId}/${exerciseId}`);
    }
    return state;
  }
}
