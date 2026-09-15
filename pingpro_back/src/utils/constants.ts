/**
 * Constantes compartidas: códigos HTTP, roles, saltos de proxy y categorías
 * del catálogo.
 *
 * `as const` congela los valores para que TypeScript los infiera como literales
 * (200, 'admin') y no como number/string genéricos.
 */
// HTTP status constants
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_ERROR: 500,
} as const;

// User roles constats
export const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
} as const;

// Saltos de proxy entre el cliente y Node en Hostinger, medidos el 2026-09-11
// con un endpoint temporal: X-Forwarded-For llegaba como
// "cliente, cliente,cliente" (un salto duplica la cabecera y el proxy local
// añade la última entrada) y la conexión venía de 127.0.0.1.
// Con 1 solo se confía en ese proxy local, cuya entrada no se pudo falsificar
// con ninguna cabecera. Con un número mayor, el cliente podría falsificar su IP
// con X-Forwarded-For (con 3 se comprobó que sí); con 0, todos compartirían la
// IP del proxy y el contador del rate limit. Si Hostinger cambia su
// infraestructura, hay que volver a medir.
export const TRUST_PROXY_HOPS = 1;

// Categorías fijas del catálogo. La app filtra comparando estos textos
// literales (pingpro_exercises_screen.dart y pingpro_trainings_screen.dart),
// así que cambiar uno rompe sus filtros. El esquema de Postgres los repetirá en
// un CHECK.
export const EXERCISE_CATEGORIES = ['Footwork', 'Técnico', 'Táctico', 'Estrategia'] as const;
export const TRAINING_CATEGORIES = ['Grado', 'Objetivo', 'Momento', 'Estilo', 'Estructura'] as const;
