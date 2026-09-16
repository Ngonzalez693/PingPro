/**
 * Lee de Firestore y de Firebase Auth todo lo que hay que migrar y lo deja en
 * la forma que espera buildMigrationPlan: documentos { id, data } con las
 * fechas ya convertidas a Date.
 *
 * Los estados se leen con collectionGroup, no recorriendo users: así aparecen
 * también los que cuelgan de un usuario sin documento (Firestore lo permite),
 * que el plan marcará como descartados.
 *
 * Este módulo SOLO LEE: nunca escribe en Firestore.
 */
import { getAuth } from 'firebase-admin/auth';
import { DocumentData, Timestamp } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import type { AuthUser, FirestoreData, FirestoreDoc, FirestoreSnapshot, StateDoc } from './plan';

// Firestore devuelve Timestamp y el plan trabaja con Date.
function toPlainData(data: DocumentData): FirestoreData {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, value instanceof Timestamp ? value.toDate() : value]),
  );
}

async function readCollection(name: string): Promise<FirestoreDoc[]> {
  const snapshot = await db.collection(name).get();
  return snapshot.docs.map((doc) => ({ id: doc.id, data: toPlainData(doc.data()) }));
}

// El uid es el padre del padre: users/{uid}/exerciseStates/{exerciseId}.
async function readStates(name: string): Promise<StateDoc[]> {
  const snapshot = await db.collectionGroup(name).get();
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    userId: doc.ref.parent.parent?.id ?? '(unknown)',
    data: toPlainData(doc.data()),
  }));
}

async function readAuthUsers(): Promise<AuthUser[]> {
  const users: AuthUser[] = [];
  let pageToken: string | undefined;
  do {
    const page = await getAuth().listUsers(1000, pageToken);
    for (const user of page.users) {
      users.push({ uid: user.uid, createdAt: new Date(user.metadata.creationTime) });
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return users;
}

export async function readFirestoreSnapshot(): Promise<FirestoreSnapshot> {
  const [users, exercises, trainings, models3d, exerciseStates, trainingStates, authUsers] = await Promise.all([
    readCollection('users'),
    readCollection('exercises'),
    readCollection('trainings'),
    readCollection('model3d'),
    readStates('exerciseStates'),
    readStates('trainingStates'),
    readAuthUsers(),
  ]);

  return { users, exercises, trainings, models3d, exerciseStates, trainingStates, authUsers };
}
