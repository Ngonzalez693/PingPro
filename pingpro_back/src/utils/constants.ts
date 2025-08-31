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
