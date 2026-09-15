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

// Ejercicios de catálogo mínimos con ids fijos, para los tests que los
// referencian (los fixtures de entrenamientos apuntan a e1, e2 y e3, y en
// Postgres tienen que existir por la clave foránea).
export async function seedExercises(pool: Pool, ids: string[]): Promise<void> {
  await pool.query(
    `INSERT INTO exercises (id, name, category, image)
     SELECT id, 'Ejercicio ' || id, 'Técnico', 'assets/images/exercise_1.jpg'
     FROM unnest($1::text[]) AS id`,
    [ids],
  );
}

// Usuarios mínimos con ids fijos, para los estados que cuelgan de ellos.
export async function seedUsers(pool: Pool, ids: string[]): Promise<void> {
  await pool.query(
    `INSERT INTO users (id, email)
     SELECT id, id || '@test.dev'
     FROM unnest($1::text[]) AS id`,
    [ids],
  );
}
