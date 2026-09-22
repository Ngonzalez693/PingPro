/**
 * Contrato del repositorio de modelos 3D (solo lectura).
 *
 * Como el repositorio no tiene create, cada enlace aporta `seed` para meter los
 * datos a su manera: el de Postgres inserta filas.
 */
import type { IModel3D } from '../../src/interfaces/models/IModel3D';
import type { IModel3DRepository } from '../../src/interfaces/repositories/IModel3DRepository';
import { model3dFixtures } from './fixtures';
import type { ContractSetup } from './types';

export type SeedModel = IModel3D & { id: string };

export interface Model3DContractSetup extends ContractSetup<IModel3DRepository> {
  seed(models: SeedModel[]): Promise<void>;
}

export function model3dRepositoryContract(name: string, setup: Model3DContractSetup): void {
  const { older, newer } = model3dFixtures;

  describe(`${name} (contrato de modelos 3D)`, () => {
    let repo: IModel3DRepository;

    beforeEach(async () => {
      await setup.reset();
      repo = setup.createRepository();
    });

    it('getAll sobre la base vacía devuelve []', async () => {
      await expect(repo.getAll()).resolves.toEqual([]);
    });

    it('getAll devuelve los modelos del más nuevo al más antiguo', async () => {
      await setup.seed([older, newer]);

      await expect(repo.getAll()).resolves.toEqual([newer, older]);
    });

    it('las fechas llegan como Date y en JSON salen como texto ISO, que es lo que lee la app', async () => {
      await setup.seed([older]);

      const model = await repo.getById(older.id);

      expect(model?.createdAt).toBeInstanceOf(Date);
      expect(model?.updatedAt).toBeInstanceOf(Date);
      // El contrato de la API expone las fechas como texto ISO.
      expect(JSON.parse(JSON.stringify(model))).toEqual({
        id: older.id,
        name: older.name,
        url: older.url,
        createdAt: '2026-01-10T10:00:00.000Z',
        updatedAt: '2026-01-12T08:00:00.000Z',
      });
    });

    it('getById devuelve el modelo exacto, o null si el id no existe', async () => {
      await setup.seed([older, newer]);

      await expect(repo.getById(newer.id)).resolves.toEqual(newer);
      await expect(repo.getById('does-not-exist')).resolves.toBeNull();
    });
  });
}
