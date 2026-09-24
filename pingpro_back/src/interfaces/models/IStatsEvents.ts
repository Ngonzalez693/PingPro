/**
 * Eventos de estadísticas de un usuario: cada finalización y cada cosa creada,
 * sueltas y sin agregar. La app los reparte en días, semanas o meses en la
 * hora local del teléfono (spec del 2026-09-24).
 *
 * session es la sesión del día (1..3) o null si no se indicó.
 */
export interface IExerciseCompletionEvent {
  exerciseId: string;
  completedAt: Date;
  session: number | null;
  category: string;
  // Códigos distintos de sus pasos, ascendentes: para contar golpes y
  // rotaciones practicados sin que la app necesite el ejercicio (puede estar
  // borrado).
  hits: number[];
  rotations: number[];
  deleted: boolean;
}

export interface ITrainingCompletionEvent {
  trainingId: string;
  completedAt: Date;
  session: number | null;
  duration: number | null;
}

export type CreatedKind = 'exercise' | 'training';

export interface ICreatedEvent {
  kind: CreatedKind;
  id: string;
  createdAt: Date;
}

export interface IStatsEvents {
  exerciseCompletions: IExerciseCompletionEvent[];
  trainingCompletions: ITrainingCompletionEvent[];
  created: ICreatedEvent[];
}
