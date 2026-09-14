/**
 * Las fechas que pone el propio repositorio (updatedAt, o completedAt al
 * marcar completado) no se pueden comparar con un valor fijo: se exige un Date
 * dentro de la ventana de la llamada.
 */
export function expectDateBetween(value: unknown, before: Date, after: Date): void {
  expect(value).toBeInstanceOf(Date);
  const time = (value as Date).getTime();
  expect(time).toBeGreaterThanOrEqual(before.getTime());
  expect(time).toBeLessThanOrEqual(after.getTime());
}
