import { FirebaseUserRepository } from '../../../src/repositories/implementations/FirebaseUserRepository';
import { db } from '../../../src/config/firebase';
import { Firestore } from 'firebase-admin/firestore';

describe('FirebaseUserRepository', () => {
  const repo = new FirebaseUserRepository();
  let collectionSpy: jest.SpyInstance;

  beforeEach(() => {
    collectionSpy = jest.spyOn(db, 'collection').mockReturnValue({
      doc: () => ({
        get: () => Promise.resolve({ exists: false } as any)
      })
    } as any);
  });

  afterEach(() => {
    collectionSpy.mockRestore();
  });

  it('getById retorna null cuando no existe', async () => {
    const result = await repo.getById('no-id');
    expect(result).toBeNull();
  });
});