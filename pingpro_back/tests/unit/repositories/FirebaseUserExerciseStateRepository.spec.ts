import { Timestamp } from 'firebase-admin/firestore';
import FirebaseUserExerciseStateRepository from '../../../src/repositories/implementations/FirebaseUserExerciseStateRepository';

// Firestore simulado: solo la cadena users/{uid}/exerciseStates que recorre el
// repositorio. El nombre empieza por "mock" para que jest permita usarlo dentro
// de la factory, que se ejecuta antes que el resto del archivo.
const mockDocs: Array<{ data: () => Record<string, unknown> }> = [];

jest.mock('firebase-admin', () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({
        collection: () => ({
          get: () => Promise.resolve({ docs: mockDocs }),
        }),
      }),
    }),
  }),
}));

describe('FirebaseUserExerciseStateRepository', () => {
  const repo = new FirebaseUserExerciseStateRepository();

  beforeEach(() => {
    mockDocs.length = 0;
  });

  it('devuelve las fechas como Date, que en JSON salen como texto ISO', async () => {
    const completed = new Date('2026-09-10T12:00:00.000Z');
    const updated = new Date('2026-09-11T08:30:00.000Z');
    mockDocs.push({
      data: () => ({
        userId: 'u1',
        exerciseId: 'e1',
        isFavorite: true,
        completedAt: Timestamp.fromDate(completed),
        updatedAt: Timestamp.fromDate(updated),
      }),
    });

    const [state] = await repo.getAllStates('u1');

    expect(state.completedAt).toEqual(completed);
    // Es lo que recibe la app. Con el Timestamp sin convertir llegaba
    // {"_seconds":…,"_nanoseconds":…} y la app lo descartaba.
    expect(JSON.parse(JSON.stringify(state))).toEqual({
      userId: 'u1',
      exerciseId: 'e1',
      isFavorite: true,
      completedAt: '2026-09-10T12:00:00.000Z',
      updatedAt: '2026-09-11T08:30:00.000Z',
    });
  });

  it('un ejercicio que no se ha completado devuelve completedAt null', async () => {
    mockDocs.push({
      data: () => ({
        userId: 'u1',
        exerciseId: 'e2',
        isFavorite: true,
        updatedAt: Timestamp.fromDate(new Date('2026-09-11T08:30:00.000Z')),
      }),
    });

    const [state] = await repo.getAllStates('u1');

    expect(state.completedAt).toBeNull();
  });
});
