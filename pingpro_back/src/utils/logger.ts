/**
 * Logger de winston con nivel según NODE_ENV.
 *
 * Configurado pero sin usar: hoy el backend registra con console.log y morgan.
 * Sustituir esos por este logger es pendiente antes de desplegar en producción,
 * donde hacen falta niveles y salida estructurada.
 */
import { createLogger, transports, format } from 'winston';

// Info for logger
const logger = createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: format.combine(
    format.timestamp(),
    format.printf(({ timestamp, level, message }) => {
      return `${timestamp} [${level.toUpperCase()}]: ${message}`;
    })
  ),
  transports: [new transports.Console()],
});

export default logger;
