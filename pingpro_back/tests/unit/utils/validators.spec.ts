import { EXERCISE_CATEGORIES, TRAINING_CATEGORIES } from '../../../src/utils/constants';
import { exerciseSchema } from '../../../src/utils/exercise.validator';
import { trainingSchema } from '../../../src/utils/training.validator';

// Cuerpos válidos: cada caso cambia un solo campo para aislar la regla.
const validStep = { hit: 1, rotation: 2, zone: 3, direction: 6, side: 1 };

function exerciseBody(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: 'Topspin cruzado',
    category: 'Técnico',
    image: 'assets/images/exercise_1.jpg',
    sequence: [validStep],
    ...overrides,
  };
}

function withStep(field: string, value: number): Record<string, unknown> {
  return exerciseBody({ sequence: [{ ...validStep, [field]: value }] });
}

function trainingBody(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: 'Calentamiento',
    category: 'Grado',
    image: 'assets/images/training_1.jpg',
    exerciseIds: ['e1'],
    duration: 20,
    ...overrides,
  };
}

// Valor más alto de cada enum de utils/enums.ts. Escritos a mano a propósito:
// si se añade un valor a un enum, este test obliga a revisarlos (y a ampliar
// el CHECK de Postgres con una migración).
const HIGHEST_CODES: Array<[string, number]> = [
  ['hit', 9],
  ['rotation', 7],
  ['zone', 4],
  ['direction', 8],
  ['side', 5],
];

describe('exerciseSchema', () => {
  it('acepta un ejercicio válido', () => {
    expect(exerciseSchema.validate(exerciseBody()).error).toBeUndefined();
  });

  it.each(HIGHEST_CODES)('acepta el valor más alto de %s (%i)', (field, highest) => {
    expect(exerciseSchema.validate(withStep(field, highest)).error).toBeUndefined();
  });

  it.each(HIGHEST_CODES)('rechaza %s por encima de su enum', (field, highest) => {
    const { error } = exerciseSchema.validate(withStep(field, highest + 1));

    expect(error?.message).toContain(field);
  });

  it.each([...EXERCISE_CATEGORIES])('acepta la categoría %s', (category) => {
    expect(exerciseSchema.validate(exerciseBody({ category })).error).toBeUndefined();
  });

  it('rechaza una categoría fuera de la lista', () => {
    const { error } = exerciseSchema.validate(exerciseBody({ category: 'Ataque' }));

    expect(error?.message).toContain('category');
  });

  // Tabla tipada: sin <[string, unknown]>, TypeScript infiere `field` como
  // string | boolean | null y no deja usarlo como clave calculada.
  it.each<[string, unknown]>([
    ['isFavorite', true],
    ['completedAt', null],
  ])('rechaza %s: es estado de cada usuario', (field, value) => {
    const { error } = exerciseSchema.validate(exerciseBody({ [field]: value }));

    expect(error?.message).toContain(field);
  });
});

describe('trainingSchema', () => {
  it('acepta un entrenamiento válido', () => {
    expect(trainingSchema.validate(trainingBody()).error).toBeUndefined();
  });

  it.each([...TRAINING_CATEGORIES])('acepta la categoría %s', (category) => {
    expect(trainingSchema.validate(trainingBody({ category })).error).toBeUndefined();
  });

  it('rechaza una categoría fuera de la lista', () => {
    const { error } = trainingSchema.validate(trainingBody({ category: 'Avanzado' }));

    expect(error?.message).toContain('category');
  });
});
