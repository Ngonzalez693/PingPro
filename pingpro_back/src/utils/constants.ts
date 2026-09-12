/**
 * Constantes compartidas: códigos HTTP, roles y saltos de proxy.
 *
 * `as const` congela los valores para que TypeScript los infiera como literales
 * (200, 'admin') y no como number/string genéricos.
 *
 * USER_ROLES se escribe en el perfil al registrarse pero todavía no se
 * comprueba en ninguna ruta: no hay autorización por rol implementada.
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
