/**
 * Inicializa el Firebase Admin SDK y expone las instancias de Firestore y Auth.
 *
 * Es el único punto del backend que toca credenciales. Se ejecuta una sola vez
 * porque Node cachea los módulos: el primer `import` dispara initializeApp() y
 * el resto reutiliza la misma conexión.
 *
 * Quien necesite Auth importa `auth` de aquí y no llama a getAuth() por su
 * cuenta: así importar el módulo garantiza que la app ya está inicializada.
 * Antes funcionaba de rebote, porque los repositorios de Firebase arrastraban
 * este archivo; al pasar el container a Postgres dejó de ser cierto.
 *
 * Las credenciales salen del .env (nunca versionado). Ver .env.example.
 *
 * Con FIRESTORE_EMULATOR_HOST definida (tests y pruebas en local) arranca sin
 * credenciales: los emuladores no las piden y el SDK les dirige Firestore y
 * Auth solo. En producción esa variable no existe y todo sigue como siempre.
 */
import { initializeApp, cert, ServiceAccount } from 'firebase-admin/app';
import { Auth, getAuth } from 'firebase-admin/auth';
import { getFirestore, Firestore } from 'firebase-admin/firestore';
import dotenv from 'dotenv';

dotenv.config();           // Look for .env configuration

const usesEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

// Última barrera: si tests/setup.ts se rompe, los tests no deben conectar con
// el proyecto real usando el .env de producción.
if (process.env.NODE_ENV === 'test' && !usesEmulator) {
  throw new Error(
    'Tests must run against the Firebase emulators: FIRESTORE_EMULATOR_HOST is not set (see tests/setup.ts)',
  );
}

if (usesEmulator) {
  initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID });
} else {
  const serviceAccount: ServiceAccount = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    // La llave privada viaja en el .env como una sola línea con "\n" literales.
    // Firebase la necesita con saltos de línea reales, de ahí el replace.
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),  // The key must be separated by \n in the same line
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  };

  initializeApp({
    credential: cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
}

// Get Firestore instance correctly
export const db: Firestore = getFirestore();

// Auth sigue siendo de Firebase después del corte a Postgres.
export const auth: Auth = getAuth();
