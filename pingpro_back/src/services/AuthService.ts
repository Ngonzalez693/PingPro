/**
 * Envuelve el módulo Auth del Admin SDK.
 *
 * Existe para que controllers y middlewares no importen firebase-admin
 * directamente: si algún día cambia el proveedor de identidad, solo se toca
 * este archivo.
 *
 * La instancia viene de config/firebase, que es quien inicializa el SDK.
 */
import type { UserRecord } from 'firebase-admin/auth';
import { auth } from '../config/firebase';

export class AuthService {
  async signUp(email: string, password: string, displayName?: string): Promise<UserRecord> {
    return auth.createUser({ email, password, displayName });
  }

  async verifyIdToken(idToken: string): Promise<string> {
    const decoded = await auth.verifyIdToken(idToken);
    return decoded.uid;
  }
}
