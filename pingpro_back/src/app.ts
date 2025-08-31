// src/app.ts
import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from '@routes/index';
import { errorHandler } from '@middlewares/index';

dotenv.config();

const app: Application = express();

// Seguridad y parsing
app.use(helmet());         // Protege HTTP headers
app.use(cors());           // Habilita CORS para todas las rutas
app.use(express.json());   // Parseo automático de JSON
app.use(morgan('dev'));    // Logging de peticiones

// Prefijo para todas las rutas de API
app.use('/api', routes);

// Manejo centralizado de errores
app.use(errorHandler);

export default app;
