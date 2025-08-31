import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from './routes';
import errorHandler from './middlewares/errorHandler';

dotenv.config();

const app: Application = express();

// Middlewares globales
app.use(helmet());                  // Seguridad HTTP headers
app.use(cors());                    // CORS
app.use(express.json());            // Parseo JSON
app.use(morgan('dev'));             // Logging

// Rutas principales
app.use('/api', routes);

// Middleware de manejo de errores
app.use(errorHandler);

export default app;
