/**
 * Contrato de los repositorios del catálogo: ejercicios y entrenamientos
 * tienen exactamente los mismos métodos, así que comparten un solo contrato
 * que recibe los datos de ejemplo de cada tipo.
 *
 * Las comparaciones son estrictas (toEqual): un repositorio no puede devolver
 * campos que no estén en el modelo. Es lo que mantuvo idéntica la respuesta de
 * la API al pasar de Firestore a Postgres.
 */
import type { ContractSetup } from './types';

// Forma común de IExerciseRepository e ITrainingRepository. Solo existe en los
// tests: las dos interfaces encajan en ella por estructura.
export interface CatalogRepository<T> {
  getAll(viewerId: string | null): Promise<T[]>;
  getById(id: string, viewerId: string | null): Promise<T | null>;
  create(item: T, ownerId: string | null): Promise<string>;
  update(id: string, patch: Partial<T>, ownerId: string | null): Promise<void>;
  delete(id: string, ownerId: string | null): Promise<void>;
  exists(id: string, viewerId: string | null): Promise<boolean>;
}

// Este contrato solo habla del catálogo, así que mira siempre con viewer null.
// Lo privado de cada usuario tiene su propio contrato.
const CATALOG_VIEWER = null;

// Dos elementos distintos y un cambio parcial para `a`. Sin id: lo asigna el repositorio.
export interface CatalogFixtures<T> {
  a: T;
  b: T;
  patch: Partial<T>;
}

const MISSING_ID = 'does-not-exist';

// Firestore y Postgres no garantizan el mismo orden en getAll: se compara ordenado.
function sortById<T extends { id?: string }>(items: T[]): T[] {
  return [...items].sort((x, y) => (x.id ?? '').localeCompare(y.id ?? ''));
}

export function catalogRepositoryContract<T extends { id?: string }>(
  name: string,
  setup: ContractSetup<CatalogRepository<T>>,
  fixtures: CatalogFixtures<T>,
): void {
  describe(`${name} (contrato de catálogo)`, () => {
    let repo: CatalogRepository<T>;

    beforeEach(async () => {
      await setup.reset();
      repo = setup.createRepository();
    });

    it('create devuelve un id y getById devuelve exactamente lo guardado', async () => {
      const id = await repo.create(fixtures.a, CATALOG_VIEWER);

      expect(typeof id).toBe('string');
      expect(id).not.toHaveLength(0);
      await expect(repo.getById(id, CATALOG_VIEWER)).resolves.toEqual({ id, ...fixtures.a });
    });

    it('getById devuelve null si el id no existe', async () => {
      await expect(repo.getById(MISSING_ID, CATALOG_VIEWER)).resolves.toBeNull();
    });

    it('getAll sobre la base vacía devuelve []', async () => {
      await expect(repo.getAll(CATALOG_VIEWER)).resolves.toEqual([]);
    });

    it('getAll devuelve todos los elementos con sus ids', async () => {
      const idA = await repo.create(fixtures.a, CATALOG_VIEWER);
      const idB = await repo.create(fixtures.b, CATALOG_VIEWER);

      const all = await repo.getAll(CATALOG_VIEWER);

      expect(sortById(all)).toEqual(
        sortById([
          { ...fixtures.a, id: idA },
          { ...fixtures.b, id: idB },
        ]),
      );
    });

    it('update aplica el cambio parcial y conserva el resto, sin añadir campos', async () => {
      const id = await repo.create(fixtures.a, CATALOG_VIEWER);

      await repo.update(id, fixtures.patch, CATALOG_VIEWER);

      await expect(repo.getById(id, CATALOG_VIEWER)).resolves.toEqual({ id, ...fixtures.a, ...fixtures.patch });
    });

    it('update rechaza si el id no existe', async () => {
      await expect(repo.update(MISSING_ID, fixtures.patch, CATALOG_VIEWER)).rejects.toThrow();
    });

    it('exists distingue un elemento creado de un id inexistente', async () => {
      const id = await repo.create(fixtures.a, CATALOG_VIEWER);

      await expect(repo.exists(id, CATALOG_VIEWER)).resolves.toBe(true);
      await expect(repo.exists(MISSING_ID, CATALOG_VIEWER)).resolves.toBe(false);
    });

    it('delete elimina el elemento', async () => {
      const id = await repo.create(fixtures.a, CATALOG_VIEWER);

      await repo.delete(id, CATALOG_VIEWER);

      await expect(repo.getById(id, CATALOG_VIEWER)).resolves.toBeNull();
      await expect(repo.exists(id, CATALOG_VIEWER)).resolves.toBe(false);
    });

    it('delete de un id inexistente no falla', async () => {
      await expect(repo.delete(MISSING_ID, CATALOG_VIEWER)).resolves.toBeUndefined();
    });
  });
}
