import { Firestore } from 'firebase-admin/firestore';
import { db as firestoreDb } from './firebase';

export interface IDatabase {
  firestore: Firestore;
  
  // more posible connections
  
}

export const database: IDatabase = {
  firestore: firestoreDb,
};
