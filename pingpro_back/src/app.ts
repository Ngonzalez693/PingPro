import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import routes from '@routes/index';
import { errorHandler } from '@middlewares/index';

dotenv.config();           // Look for .env configuration

const app: Application = express();

// Security and parsing
app.use(helmet());         // Protect HTTP headers
app.use(cors());           // Enable CORS for all routes
app.use(express.json());   // JSON automatic parsing
app.use(morgan('dev'));    // Logging of petitions

// Prefix for all API routes
app.use('/api', routes);

// Error centralized control
app.use(errorHandler);

export default app;
