/**
 * Constantes compartidas: códigos HTTP y roles.
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
  INTERNAL_ERROR: 500,
} as const;

// User roles constats
export const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
} as const;
