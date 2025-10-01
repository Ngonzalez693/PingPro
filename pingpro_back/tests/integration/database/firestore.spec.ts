import { initializeApp, firestore } from 'firebase-admin';

initializeApp({
  projectId: 'demo-test',
});

const db = firestore();

describe('Firestore Emulator', () => {
  it('escribe y lee un documento', async () => {
    const ref = db.collection('tests').doc('doc1');
    await ref.set({ foo: 'bar' });
    const snap = await ref.get();
    expect(snap.data()).toEqual({ foo: 'bar' });
  });
});