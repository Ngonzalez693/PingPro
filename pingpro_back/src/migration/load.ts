/**
 * Carga en Postgres las filas del plan de migración.
 *
 * loadRows vacía y carga todo dentro de una sola transacción: o entra el
 * Firestore completo o no entra nada. Se niega a escribir si la base ya tiene
 * datos, salvo que se pase replace: es la protección para no borrar sin querer
 * lo que la app haya escrito después del corte.
 *
 * Los nombres de tabla y de columna salen del propio plan (TABLES y las claves
 * de cada fila), nunca de datos de usuario.
 */
import type { Pool, PoolClient } from 'pg';
import { withTransaction } from '../db/transaction';
import type { MigrationRows } from './plan';

// Orden de inserción: primero las tablas de las que dependen las demás.
const TABLES: Array<keyof MigrationRows> = [
  'users',
  'exercises',
  'exercise_steps',
  'trainings',
  'training_exercises',
  'models_3d',
  'user_exercise_states',
  'exercise_completions',
  'user_training_states',
  'training_completions',
];

type Row = Record<string, unknown>;

function insertSql(table: string, columns: string[], onConflictDoNothing = false): string {
  const params = columns.map((_, index) => `$${index + 1}`);
  const conflict = onConflictDoNothing ? ' ON CONFLICT (id) DO NOTHING' : '';
  return `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${params.join(', ')})${conflict}`;
}

async function insertRows(client: PoolClient, table: string, rows: Row[]): Promise<void> {
  for (const row of rows) {
    const columns = Object.keys(row);
    await client.query(
      insertSql(table, columns),
      columns.map((column) => row[column]),
    );
  }
}

// Privada: solo la usa loadRows para decidir si la base está vacía.
async function countRows(pool: Pool): Promise<number> {
  const results = await Promise.all(
    TABLES.map((table) => pool.query<{ total: number }>(`SELECT count(*)::int AS total FROM ${table}`)),
  );
  return results.reduce((total, result) => total + result.rows[0].total, 0);
}

export async function loadRows(pool: Pool, rows: MigrationRows, options: { replace: boolean }): Promise<void> {
  if (!options.replace && (await countRows(pool)) > 0) {
    throw new Error('The target database already has data: pass --replace to empty it first');
  }

  await withTransaction(pool, async (client) => {
    await client.query(`TRUNCATE ${TABLES.join(', ')} RESTART IDENTITY CASCADE`);
    for (const table of TABLES) {
      await insertRows(client, table, rows[table] as unknown as Row[]);
    }
  });
}

// Solo añade los perfiles que falten: nunca borra ni pisa nada. Es lo que se
// lanza después del corte, por si alguien se registró entre el volcado y el
// despliegue. Devuelve cuántos insertó.
export async function insertMissingUsers(pool: Pool, rows: MigrationRows): Promise<number> {
  let inserted = 0;
  for (const user of rows.users) {
    const columns = Object.keys(user);
    const { rowCount } = await pool.query(
      insertSql('users', columns, true),
      columns.map((column) => (user as unknown as Row)[column]),
    );
    inserted += rowCount ?? 0;
  }
  return inserted;
}
