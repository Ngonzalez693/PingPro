import { buildMigrationPlan, FirestoreSnapshot, MigrationPlan, ProblemKind } from '../../../src/migration/plan';

const NOW = new Date('2026-09-14T12:00:00.000Z');
const CREATED = new Date('2026-03-01T12:00:00.000Z');
const AUTH_CREATED = new Date('2026-02-01T09:00:00.000Z');
const COMPLETED = new Date('2026-09-10T08:00:00.000Z');

const step = { hit: 1, rotation: 2, zone: 3, direction: 6, side: 1, ownZone: 4 };

// Un Firestore pequeño y válido; cada caso cambia solo lo que prueba.
function snapshot(overrides: Partial<FirestoreSnapshot> = {}): FirestoreSnapshot {
  return {
    users: [
      { id: 'u1', data: { email: 'ana@test.dev', displayName: 'Ana', roles: ['user'], createdAt: CREATED, updatedAt: CREATED } },
    ],
    exercises: [
      { id: 'e1', data: { name: 'Topspin', category: 'Técnico', image: 'a.jpg', sequence: [step, { ...step, hit: 2 }] } },
      { id: 'e2', data: { name: 'Flick', category: 'Táctico', image: 'b.jpg', description: 'Corto', sequence: [step] } },
    ],
    trainings: [
      { id: 't1', data: { name: 'Calentamiento', category: 'Grado', image: 't.jpg', exerciseIds: ['e2', 'e1', 'e2'], duration: 20 } },
    ],
    models3d: [
      { id: 'm1', data: { name: 'Forehand Topspin', url: 'https://example.com/m1.glb', createdAt: CREATED, updatedAt: CREATED } },
    ],
    exerciseStates: [
      { id: 'e1', userId: 'u1', data: { isFavorite: true, completedAt: COMPLETED, updatedAt: COMPLETED } },
    ],
    trainingStates: [
      { id: 't1', userId: 'u1', data: { completedAt: COMPLETED, updatedAt: COMPLETED, progress: 40 } },
    ],
    authUsers: [{ uid: 'u1', createdAt: AUTH_CREATED }],
    ...overrides,
  };
}

function problemsOf(plan: MigrationPlan, kind: ProblemKind): string[] {
  return plan.problems.filter((problem) => problem.kind === kind).map((problem) => problem.path);
}

describe('buildMigrationPlan', () => {
  it('un Firestore válido no tiene problemas y produce todas las filas', () => {
    const plan = buildMigrationPlan(snapshot(), NOW);

    expect(plan.problems).toEqual([]);
    expect(plan.rows.users).toEqual([
      {
        id: 'u1',
        email: 'ana@test.dev',
        display_name: 'Ana',
        photo_url: null,
        roles: ['user'],
        created_at: CREATED,
        updated_at: CREATED,
      },
    ]);
    expect(plan.rows.exercises.map((row) => [row.id, row.description])).toEqual([
      ['e1', null],
      ['e2', 'Corto'],
    ]);
    expect(plan.rows.exercise_steps.filter((row) => row.exercise_id === 'e1')).toEqual([
      {
        exercise_id: 'e1',
        position: 0,
        hit: step.hit,
        rotation: step.rotation,
        zone: step.zone,
        direction: step.direction,
        side: step.side,
        own_zone: step.ownZone,
      },
      {
        exercise_id: 'e1',
        position: 1,
        hit: 2,
        rotation: step.rotation,
        zone: step.zone,
        direction: step.direction,
        side: step.side,
        own_zone: step.ownZone,
      },
    ]);
    expect(plan.rows.trainings).toEqual([
      {
        id: 't1',
        name: 'Calentamiento',
        category: 'Grado',
        image: 't.jpg',
        description: null,
        duration: 20,
        created_at: NOW,
        updated_at: NOW,
      },
    ]);
    expect(plan.rows.training_exercises).toEqual([
      { training_id: 't1', position: 0, exercise_id: 'e2' },
      { training_id: 't1', position: 1, exercise_id: 'e1' },
      { training_id: 't1', position: 2, exercise_id: 'e2' },
    ]);
    expect(plan.rows.models_3d).toEqual([
      { id: 'm1', name: 'Forehand Topspin', url: 'https://example.com/m1.glb', created_at: CREATED, updated_at: CREATED },
    ]);
    expect(plan.rows.user_exercise_states).toEqual([
      { user_id: 'u1', exercise_id: 'e1', is_favorite: true, updated_at: COMPLETED },
    ]);
    expect(plan.rows.exercise_completions).toEqual([{ user_id: 'u1', exercise_id: 'e1', completed_at: COMPLETED }]);
    expect(plan.rows.user_training_states).toEqual([{ user_id: 'u1', training_id: 't1', updated_at: COMPLETED }]);
    expect(plan.rows.training_completions).toEqual([{ user_id: 'u1', training_id: 't1', completed_at: COMPLETED }]);
  });

  it('las fechas de un usuario que faltan salen de Auth y, si no, de now', () => {
    const plan = buildMigrationPlan(
      snapshot({
        users: [
          { id: 'u1', data: { email: 'ana@test.dev' } },
          { id: 'u2', data: { email: 'ben@test.dev' } },
        ],
        authUsers: [{ uid: 'u1', createdAt: AUTH_CREATED }],
        exerciseStates: [],
        trainingStates: [],
      }),
      NOW,
    );

    expect(plan.rows.users.map((row) => [row.id, row.created_at, row.updated_at])).toEqual([
      ['u1', AUTH_CREATED, AUTH_CREATED],
      ['u2', NOW, NOW],
    ]);
  });

  it('un usuario sin email bloquea', () => {
    const plan = buildMigrationPlan(snapshot({ users: [{ id: 'u1', data: { displayName: 'Ana' } }] }), NOW);

    expect(problemsOf(plan, 'blocking')).toEqual(['users/u1']);
  });

  it('una cuenta de Auth sin perfil es un aviso', () => {
    const plan = buildMigrationPlan(
      snapshot({ authUsers: [{ uid: 'u1', createdAt: AUTH_CREATED }, { uid: 'u9', createdAt: NOW }] }),
      NOW,
    );

    expect(problemsOf(plan, 'warning')).toEqual(['auth/u9']);
  });

  it('una categoría fuera de la lista o un código fuera de su enum bloquean', () => {
    const plan = buildMigrationPlan(
      snapshot({
        exercises: [
          { id: 'e1', data: { name: 'Topspin', category: 'Ataque', image: 'a.jpg', sequence: [step] } },
          { id: 'e2', data: { name: 'Flick', category: 'Táctico', image: 'b.jpg', sequence: [{ ...step, hit: 99 }] } },
        ],
        trainings: [],
        exerciseStates: [],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'blocking')).toEqual(['exercises/e1', 'exercises/e2']);
    expect(plan.rows.exercises).toEqual([]);
  });

  it('los campos por usuario sueltos en un ejercicio se avisan y no se migran', () => {
    const plan = buildMigrationPlan(
      snapshot({
        exercises: [
          {
            id: 'e1',
            data: { name: 'Topspin', category: 'Técnico', image: 'a.jpg', sequence: [step], isFavorite: true, completedAt: COMPLETED },
          },
          { id: 'e2', data: { name: 'Flick', category: 'Táctico', image: 'b.jpg', sequence: [step] } },
        ],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'warning')).toEqual(['exercises/e1']);
    expect(plan.rows.exercises.map((row) => row.id)).toEqual(['e1', 'e2']);
  });

  it('un entrenamiento descarta los ejercicios que no existen y avisa si se queda vacío', () => {
    const plan = buildMigrationPlan(
      snapshot({
        trainings: [
          { id: 't1', data: { name: 'Mixto', category: 'Grado', image: 't.jpg', exerciseIds: ['e1', 'e9', 'e2'] } },
          { id: 't2', data: { name: 'Vacío', category: 'Objetivo', image: 't.jpg', exerciseIds: ['e8'] } },
        ],
        trainingStates: [],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'discarded')).toEqual(['trainings/t1', 'trainings/t2']);
    expect(problemsOf(plan, 'warning')).toEqual(['trainings/t2']);
    expect(plan.rows.training_exercises).toEqual([
      { training_id: 't1', position: 0, exercise_id: 'e1' },
      { training_id: 't1', position: 1, exercise_id: 'e2' },
    ]);
  });

  it('un entrenamiento con duración negativa bloquea', () => {
    const plan = buildMigrationPlan(
      snapshot({
        trainings: [{ id: 't1', data: { name: 'Mal', category: 'Grado', image: 't.jpg', exerciseIds: ['e1'], duration: -5 } }],
        trainingStates: [],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'blocking')).toEqual(['trainings/t1']);
  });

  it('un nombre de modelo 3D repetido bloquea', () => {
    const plan = buildMigrationPlan(
      snapshot({
        models3d: [
          { id: 'm1', data: { name: 'Forehand Topspin', url: 'https://example.com/m1.glb' } },
          { id: 'm2', data: { name: 'Forehand Topspin', url: 'https://example.com/m2.glb' } },
        ],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'blocking')).toEqual(['model3d/m2']);
    expect(plan.rows.models_3d.map((row) => [row.id, row.created_at])).toEqual([['m1', NOW]]);
  });

  it('los estados huérfanos se descartan y un completedAt nulo no crea historial', () => {
    const plan = buildMigrationPlan(
      snapshot({
        exerciseStates: [
          { id: 'e1', userId: 'u1', data: { completedAt: null } },
          { id: 'e9', userId: 'u1', data: { isFavorite: true } },
          { id: 'e2', userId: 'u9', data: { isFavorite: true } },
        ],
        trainingStates: [{ id: 't9', userId: 'u1', data: { completedAt: COMPLETED } }],
      }),
      NOW,
    );

    expect(problemsOf(plan, 'discarded')).toEqual([
      'users/u1/exerciseStates/e9',
      'users/u9/exerciseStates/e2',
      'users/u1/trainingStates/t9',
    ]);
    expect(plan.rows.user_exercise_states).toEqual([
      { user_id: 'u1', exercise_id: 'e1', is_favorite: null, updated_at: NOW },
    ]);
    expect(plan.rows.exercise_completions).toEqual([]);
    expect(plan.rows.training_completions).toEqual([]);
  });
});
