/**
 * Inicializa el Firebase Admin SDK y expone la instancia de Firestore.
 *
 * Es el único punto del backend que toca credenciales. Se ejecuta una sola vez
 * porque Node cachea los módulos: el primer `import` dispara initializeApp() y
 * el resto reutiliza la misma conexión.
 *
 * Las credenciales salen del .env (nunca versionado). Ver .env.example.
 */
import { initializeApp, cert, ServiceAccount } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';
import dotenv from 'dotenv';

dotenv.config();           // Look for .env configuration

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

// Get Firestore instance correctly
export const db: Firestore = getFirestore();
