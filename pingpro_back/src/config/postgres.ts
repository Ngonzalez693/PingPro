/**
 * Conexión a Postgres: Supabase en producción, el PostgreSQL 17 del PC en
 * desarrollo y en los tests.
 *
 * poolConfig() es pura para poder probarla sin conectar: decide el SSL y
 * aplica las barreras. createPool() la usa con DATABASE_URL. No se exporta un
 * pool ya creado: quien lo necesite (el container, el runner de migraciones,
 * los tests) crea el suyo y lo cierra.
 *
 * Fuera de la máquina local, el certificado del servidor se verifica con la CA
 * de Supabase (certs/supabase-ca.crt). Nunca rejectUnauthorized: false: el
 * tráfico iría cifrado pero sin saber con quién se habla.
 */
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { Pool, PoolConfig } from 'pg';

dotenv.config();

const CA_PATH = path.resolve(__dirname, '../../certs/supabase-ca.crt');
const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);

// La API es un solo proceso y el pooler del plan gratis de Supabase limita las
// conexiones: con 5 sobra.
const MAX_CONNECTIONS = 5;

export function poolConfig(connectionString: string | undefined, nodeEnv: string | undefined): PoolConfig {
  if (!connectionString) {
    throw new Error('DATABASE_URL is not set (see .env.example)');
  }

  const url = new URL(connectionString);
  // pg deja que los parámetros de la URL pisen la opción ssl de abajo.
  if (url.searchParams.has('sslmode')) {
    throw new Error('Remove sslmode from DATABASE_URL: SSL is configured in src/config/postgres.ts');
  }

  const isLocal = LOCAL_HOSTS.has(url.hostname);
  const database = url.pathname.slice(1);

  // Última barrera, como en config/firebase.ts: aunque tests/setup.ts falle,
  // los tests nunca tocan una base que no sea local y de test.
  if (nodeEnv === 'test' && (!isLocal || !database.endsWith('_test'))) {
    throw new Error('Tests must use a local *_test database (see tests/setup.ts)');
  }

  return {
    connectionString,
    max: MAX_CONNECTIONS,
    ssl: isLocal ? false : { ca: readSupabaseCa(), rejectUnauthorized: true },
  };
}

function readSupabaseCa(): string {
  if (!fs.existsSync(CA_PATH)) {
    throw new Error(`Supabase CA certificate not found at ${CA_PATH}`);
  }
  return fs.readFileSync(CA_PATH, 'utf8');
}

export function createPool(): Pool {
  return new Pool(poolConfig(process.env.DATABASE_URL, process.env.NODE_ENV));
}
