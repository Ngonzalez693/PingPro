/**
 * Declaraciones de tipos globales.
 *
 * ProcessEnv documenta qué variables espera el backend en el .env y hace que
 * process.env.X salga tipado en vez de string | undefined.
 */
declare namespace NodeJS {
  interface ProcessEnv {
    NODE_ENV: 'development' | 'production' | 'test'; // jest pone 'test'
    PORT?: string;
    JWT_SECRET: string;
    FIREBASE_PROJECT_ID: string;
    FIREBASE_PRIVATE_KEY: string;
    FIREBASE_CLIENT_EMAIL: string;
    FIREBASE_API_KEY: string;
    FIREBASE_AUTH_DOMAIN: string;
    FIREBASE_STORAGE_BUCKET: string;
    FIREBASE_MESSAGING_SENDER_ID: string;
    FIREBASE_APP_ID: string;
    FIREBASE_MEASUREMENT_ID: string;
    // other env vars
  }
}

