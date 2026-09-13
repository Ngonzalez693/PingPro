/**
 * Utilidades de los tests de integración: vacían los emuladores entre casos,
 * piden tokens reales al emulador de Auth y cierran Firebase al terminar.
 *
 * Las direcciones y el proyecto salen de tests/setup.ts.
 */
import { deleteApp, getApp } from 'firebase-admin/app';

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not set (see tests/setup.ts)`);
  return value;
}

async function ensureOk(res: Response, action: string): Promise<void> {
  if (res.ok) return;
  throw new Error(`${action} failed: HTTP ${res.status} ${await res.text()}`);
}

export async function clearFirestore(): Promise<void> {
  const host = requiredEnv('FIRESTORE_EMULATOR_HOST');
  const project = requiredEnv('FIREBASE_PROJECT_ID');
  const res = await fetch(
    `http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  await ensureOk(res, 'Clearing the Firestore emulator');
}

export async function clearAuth(): Promise<void> {
  const host = requiredEnv('FIREBASE_AUTH_EMULATOR_HOST');
  const project = requiredEnv('FIREBASE_PROJECT_ID');
  const res = await fetch(`http://${host}/emulator/v1/projects/${project}/accounts`, {
    method: 'DELETE',
  });
  await ensureOk(res, 'Clearing the Auth emulator');
}

// Hace lo mismo que la app al iniciar sesión: el emulador devuelve un ID token
// que verifyIdToken acepta. Cualquier `key` vale contra el emulador.
export async function signInWithEmulator(email: string, password: string): Promise<string> {
  const host = requiredEnv('FIREBASE_AUTH_EMULATOR_HOST');
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  await ensureOk(res, 'Signing in on the Auth emulator');

  const body = (await res.json()) as { idToken?: unknown };
  if (typeof body.idToken !== 'string') {
    throw new Error('The Auth emulator did not return an idToken');
  }
  return body.idToken;
}

// Cierra las conexiones de Firestore y Auth. Sin esto jest no termina y
// `firebase emulators:exec` nunca apaga los emuladores.
export async function closeFirebaseApp(): Promise<void> {
  await deleteApp(getApp());
}
