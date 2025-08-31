import 'express';

declare module 'express' {
  export interface Request {
    user?: { uid: string };
  }
}
