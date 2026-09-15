/**
 * Ejecuta fn dentro de una transacción con una conexión propia del pool:
 * COMMIT si termina bien, ROLLBACK si lanza. Lo usan las escrituras que tocan
 * varias tablas a la vez (un ejercicio y sus pasos, un entrenamiento y sus
 * ejercicios), para que nunca quede una mitad guardada.
 */
import type { Pool, PoolClient } from 'pg';

export async function withTransaction<T>(pool: Pool, fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
