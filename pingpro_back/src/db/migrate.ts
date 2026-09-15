/**
 * Aplica las migraciones SQL de db/migrations en orden de nombre, una sola vez
 * cada una.
 *
 * Cada archivo corre en su propia transacción junto con su registro en
 * schema_migrations: si falla a medias, no queda nada aplicado ni registrado.
 *
 * Uso: `npm run db:migrate` contra la base de DATABASE_URL. Para producción,
 * Nicolás fija DATABASE_URL en la sesión de PowerShell con Read-Host (nunca en
 * el .env ni en el historial) y la quita al terminar.
 */
import fs from 'fs';
import path from 'path';
import type { Pool } from 'pg';
import { createPool } from '../config/postgres';

// Misma profundidad desde src/db y desde dist/db.
const MIGRATIONS_DIR = path.resolve(__dirname, '../../db/migrations');
const MIGRATION_FILE = /^\d{4}_[a-z0-9_]+\.sql$/;

export async function migrate(pool: Pool): Promise<string[]> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version    text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    );
    ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;
  `);

  const { rows } = await pool.query<{ version: string }>('SELECT version FROM schema_migrations');
  const applied = new Set(rows.map((row) => row.version));

  const pending = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => MIGRATION_FILE.test(file))
    .sort()
    .map((file) => file.replace(/\.sql$/, ''))
    .filter((version) => !applied.has(version));

  for (const version of pending) {
    await applyMigration(pool, version);
  }
  return pending;
}

async function applyMigration(pool: Pool, version: string): Promise<void> {
  const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, `${version}.sql`), 'utf8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [version]);
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Solo al lanzarlo como script (npm run db:migrate), no al importarlo en los
// tests. Imprime el destino sin la contraseña antes de tocar nada.
async function runFromCli(): Promise<void> {
  const pool = createPool();
  const target = new URL(String(process.env.DATABASE_URL));
  console.log(`Migrating ${target.hostname}:${target.port}/${target.pathname.slice(1)}`);
  try {
    const applied = await migrate(pool);
    console.log(applied.length > 0 ? `Applied: ${applied.join(', ')}` : 'Nothing to apply');
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  runFromCli().catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  });
}
