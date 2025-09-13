import { getAuth, UserRecord } from 'firebase-admin/auth';

export class AuthService {
  private auth = getAuth();

  async signUp(email: string, password: string, displayName?: string): Promise<UserRecord> {
    return this.auth.createUser({ email, password, displayName });
  }

  async verifyIdToken(idToken: string): Promise<string> {
    const decoded = await this.auth.verifyIdToken(idToken);
    return decoded.uid;
  }
}
