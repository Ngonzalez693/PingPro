/**
 * Utilidades de los tests contra el PostgreSQL local (base pingpro_test, ver
 * tests/setup.ts y db/create-test-database.sql).
 */
import type { Pool } from 'pg';

// Todas las tablas de datos de 0001. TRUNCATE ... CASCADE resuelve el orden de
// las claves foráneas; schema_migrations no se toca.
const DATA_TABLES = [
  'users',
  'exercises',
  'exercise_steps',
  'trainings',
  'training_exercises',
  'user_exercise_states',
  'exercise_completions',
  'user_training_states',
  'training_completions',
  'models_3d',
];

export async function resetPostgres(pool: Pool): Promise<void> {
  await pool.query(`TRUNCATE ${DATA_TABLES.join(', ')} RESTART IDENTITY CASCADE`);
}

// Deja la base como recién creada, para probar que las migraciones se aplican
// desde cero. pingpro_test es dueño de la base, así que puede recrear public.
export async function recreateSchema(pool: Pool): Promise<void> {
  await pool.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
}
