/**
 * Capa de indirección sobre firebase.ts: los repositorios importan `database`
 * en vez de la instancia cruda de Firestore.
 *
 * El motivo es poder sumar otra fuente de datos (o cambiar Firestore por otra)
 * tocando solo este archivo, sin editar cada repositorio.
 */
import { Firestore } from 'firebase-admin/firestore';
import { db as firestoreDb } from './firebase';

export interface IDatabase {
  firestore: Firestore;

  // more posible connections

}

export const database: IDatabase = {
  firestore: firestoreDb,
};
