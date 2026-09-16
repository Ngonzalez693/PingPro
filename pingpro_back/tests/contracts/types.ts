/**
 * Piezas comunes de los contratos de repositorio.
 *
 * Un contrato es una batería de tests escrita contra una interfaz, no contra
 * una base de datos: cada implementación la ejecuta desde su propio archivo de
 * enlace, pasándole un ContractSetup. Hoy solo queda la de Postgres, pero el
 * contrato es lo que habría que cumplir para cambiar otra vez de base.
 */
export interface ContractSetup<R> {
  // Una instancia nueva por test.
  createRepository(): R;
  // Deja la base de datos vacía antes de cada test.
  reset(): Promise<void>;
}
