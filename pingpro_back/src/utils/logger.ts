/**
 * Logger de winston con nivel según NODE_ENV.
 *
 * Lo usa errorHandler para registrar los errores internos (los que no se le
 * enseñan al usuario). El resto del backend aún registra con console.log y
 * morgan.
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
