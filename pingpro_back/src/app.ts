/**
 * Arma la aplicación de Express: middlewares globales, montaje de rutas y
 * manejador de errores. No abre el puerto — de eso se encarga server.ts.
 *
 * El orden de los `use` importa: los middlewares corren en el mismo orden en
 * que se registran, y el errorHandler debe ir de último para recibir lo que
 * los anteriores dejen pasar con `next(err)`.
 */
import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from './routes/index';
import { errorHandler } from './middlewares/index';

dotenv.config();           // Look for .env configuration

const app: Application = express();

// Security and parsing
app.use(helmet());         // Protect HTTP headers
app.use(cors());           // Enable CORS for all routes
app.use(express.json());   // JSON automatic parsing
app.use(morgan('dev'));    // Logging of petitions

// Prefix for all API routes
// Todo cuelga de /api: /api/exercises, /api/trainings, /api/users, /api/auth,
// /api/stats y /api/model3d (ver routes/index.ts).
app.use('/api', routes);

// Error centralized control
app.use(errorHandler);

export default app;
