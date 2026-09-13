/**
 * Piezas comunes de los contratos de repositorio.
 *
 * Un contrato es una batería de tests escrita contra una interfaz, no contra
 * una base de datos: cada implementación (Firebase hoy, Supabase mañana) la
 * ejecuta desde su propio archivo de enlace, pasándole un ContractSetup.
 */
export interface ContractSetup<R> {
  // Una instancia nueva por test.
  createRepository(): R;
  // Deja la base de datos vacía antes de cada test.
  reset(): Promise<void>;
}
