/**
 * Implementación en Postgres de IUserTrainingStateRepository. Igual que la de
 * ejercicios, sin favorito: user_training_states guarda cuándo se tocó el
 * estado y training_completions el historial. completedAt es la finalización
 * más reciente y setCompleted(false) deshace esa última.
 *
 * Las fechas salen del reloj de Node, como en Firestore.
 */
import type { Pool, PoolClient } from 'pg';
import type { IUserTrainingState } from '../../interfaces/models/IUserTrainingState';
import type { IUserTrainingStateRepository } from '../../interfaces/repositories/IUserTrainingStateRepository';
import { withTransaction } from '../../db/transaction';

interface StateRow {
  user_id: string;
  training_id: string;
  updated_at: Date;
  completed_at: Date | null;
}

const SELECT_STATES = `
  SELECT s.user_id, s.training_id, s.updated_at,
         (SELECT max(c.completed_at)
          FROM training_completions c
          WHERE c.user_id = s.user_id AND c.training_id = s.training_id) AS completed_at
  FROM user_training_states s
  WHERE s.user_id = $1`;

function toState(row: StateRow): IUserTrainingState {
  return {
    userId: row.user_id,
    trainingId: row.training_id,
    completedAt: row.completed_at,
    updatedAt: row.updated_at,
  };
}

async function touchState(client: PoolClient, userId: string, trainingId: string, now: Date): Promise<void> {
  await client.query(
    `INSERT INTO user_training_states (user_id, training_id, updated_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, training_id) DO UPDATE SET updated_at = EXCLUDED.updated_at`,
    [userId, trainingId, now],
  );
}

export class PostgresUserTrainingStateRepository implements IUserTrainingStateRepository {
  constructor(private readonly pool: Pool) {}

  // true añade una fila al historial; false borra la más reciente (deshacer).
  async setCompleted(
    userId: string,
    trainingId: string,
    completed: boolean,
    session: number | null = null,
  ): Promise<IUserTrainingState> {
    const now = new Date();
    await withTransaction(this.pool, async (client) => {
      if (completed) {
        await client.query(
          'INSERT INTO training_completions (user_id, training_id, completed_at, session) VALUES ($1, $2, $3, $4)',
          [userId, trainingId, now, session],
        );
      } else {
        await client.query(
          `DELETE FROM training_completions
           WHERE id = (SELECT id FROM training_completions
                       WHERE user_id = $1 AND training_id = $2
                       ORDER BY completed_at DESC, id DESC
                       LIMIT 1)`,
          [userId, trainingId],
        );
      }
      await touchState(client, userId, trainingId, now);
    });

    const state = await this.getState(userId, trainingId);
    if (!state) {
      throw new Error(`Training state not found after writing: ${userId}/${trainingId}`);
    }
    return state;
  }

  async getState(userId: string, trainingId: string): Promise<IUserTrainingState | null> {
    const { rows } = await this.pool.query<StateRow>(`${SELECT_STATES} AND s.training_id = $2`, [userId, trainingId]);
    return rows.length > 0 ? toState(rows[0]) : null;
  }

  async getAllStates(userId: string): Promise<IUserTrainingState[]> {
    const { rows } = await this.pool.query<StateRow>(SELECT_STATES, [userId]);
    return rows.map(toState);
  }
}
