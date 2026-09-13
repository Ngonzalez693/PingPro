import type { CollectionReference } from 'firebase-admin/firestore';
import { FirebaseUserRepository } from '../../../src/repositories/implementations/FirebaseUserRepository';
import { db } from '../../../src/config/firebase';

describe('FirebaseUserRepository', () => {
  let collectionSpy: jest.SpyInstance;

  beforeEach(() => {
    collectionSpy = jest.spyOn(db, 'collection').mockReturnValue({
      doc: () => ({
        get: () => Promise.resolve({ exists: false }),
      }),
    } as unknown as CollectionReference);
  });

  afterEach(() => {
    collectionSpy.mockRestore();
  });

  it('getById retorna null cuando no existe', async () => {
    // El repositorio guarda la colección al construirse, así que se crea
    // después de simular db.collection. Creado antes, usaba la colección real
    // y este test leía Firestore de verdad.
    const repo = new FirebaseUserRepository();

    const result = await repo.getById('no-id');

    expect(result).toBeNull();
    expect(collectionSpy).toHaveBeenCalledWith('users');
  });
});
