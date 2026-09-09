/**
 * Barrel de middlewares: agrupa auth, manejo de errores y validación en un solo
 * punto de import (`@middlewares/index`).
 */
// Middlewares barrel
export { default as authMiddleware } from './authMiddleware';
export { default as errorHandler } from './errorHandler';
export * from './validation';
