import { db } from '../../../src/config/firebase';
import { clearFirestore, closeFirebaseApp } from '../helpers/emulators';

// Usa el db del backend y no una conexión propia: comprueba que nuestra
// configuración, en modo emulador, escribe y lee de verdad. Es la base de los
// tests de contrato de los repositorios (PR C2).
describe('Firestore (emulador)', () => {
  beforeEach(clearFirestore);
  afterAll(closeFirebaseApp);

  it('escribe y lee un documento con la configuración del backend', async () => {
    const ref = db.collection('_tests').doc('doc1');

    await ref.set({ foo: 'bar' });
    const snap = await ref.get();

    expect(snap.data()).toEqual({ foo: 'bar' });
  });
});
