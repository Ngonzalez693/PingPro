/**
 * Contrato del repositorio de perfiles de usuario (users/{uid}).
 *
 * El id del perfil es siempre el uid de Firebase Auth, así que el contrato
 * crea con createWithUID y consulta por ese uid.
 */
import type { IUserRepository } from '../../src/interfaces/repositories/IUserRepository';
import { expectDateBetween } from './dates';
import { userFixtures } from './fixtures';
import type { ContractSetup } from './types';

const UID = 'uid-ana';
const MISSING_UID = 'uid-missing';

export function userRepositoryContract(name: string, setup: ContractSetup<IUserRepository>): void {
  const { user, patch } = userFixtures;

  describe(`${name} (contrato de usuarios)`, () => {
    let repo: IUserRepository;

    beforeEach(async () => {
      await setup.reset();
      repo = setup.createRepository();
    });

    it('createWithUID guarda el perfil con el uid indicado', async () => {
      await repo.createWithUID(UID, user);

      await expect(repo.getById(UID)).resolves.toEqual({ id: UID, ...user });
    });

    it('getById devuelve null si el uid no existe', async () => {
      await expect(repo.getById(MISSING_UID)).resolves.toBeNull();
    });

    it('las fechas llegan como Date y en JSON salen como texto ISO', async () => {
      await repo.createWithUID(UID, user);

      const profile = await repo.getById(UID);

      expect(profile?.createdAt).toBeInstanceOf(Date);
      expect(profile?.updatedAt).toBeInstanceOf(Date);
      // Es lo que devuelve GET /api/users/me.
      expect(JSON.parse(JSON.stringify(profile))).toEqual({
        id: UID,
        email: user.email,
        displayName: user.displayName,
        roles: user.roles,
        createdAt: '2026-03-01T12:00:00.000Z',
        updatedAt: '2026-03-01T12:00:00.000Z',
      });
    });

    it('update aplica el cambio, conserva el resto y actualiza updatedAt', async () => {
      await repo.createWithUID(UID, user);

      const before = new Date();
      await repo.update(UID, patch);
      const after = new Date();
      const profile = await repo.getById(UID);

      expect(profile).toEqual({ id: UID, ...user, ...patch, updatedAt: expect.any(Date) });
      expectDateBetween(profile?.updatedAt, before, after);
    });

    it('update rechaza si el uid no existe', async () => {
      await expect(repo.update(MISSING_UID, patch)).rejects.toThrow();
    });

    it('delete elimina el perfil', async () => {
      await repo.createWithUID(UID, user);

      await repo.delete(UID);

      await expect(repo.getById(UID)).resolves.toBeNull();
    });

    it('delete de un uid inexistente no falla', async () => {
      await expect(repo.delete(MISSING_UID)).resolves.toBeUndefined();
    });
  });
}
