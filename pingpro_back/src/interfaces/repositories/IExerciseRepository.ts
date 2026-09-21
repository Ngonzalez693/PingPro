/**
 * Contrato de persistencia de ejercicios (patrón Repository).
 *
 * ExerciseService depende de esta interfaz, no de la implementación de
 * Firestore. Es la frontera que permite cambiar de base de datos escribiendo
 * otra clase en repositories/implementations sin tocar la lógica de negocio.
 *
 * Las lecturas reciben `viewerId`: quién está mirando decide qué se ve, porque
 * además del catálogo cada usuario tiene sus ejercicios privados.
 *   - un uid  → catálogo + lo privado de ese usuario
 *   - null    → solo catálogo, que es lo que tocan las operaciones de admin
 * Lo que no se ve no existe: getById devuelve null, no un error de permiso.
 */
import { IExercise } from '../models/IExercise';

// Interface for exercise repository
export interface IExerciseRepository {
  getAll(viewerId: string | null): Promise<IExercise[]>;
  getById(id: string, viewerId: string | null): Promise<IExercise | null>;
  create(exercise: IExercise): Promise<string>;
  update(id: string, exercise: Partial<IExercise>): Promise<void>;
  delete(id: string): Promise<void>;

  exists(id: string, viewerId: string | null): Promise<boolean>;
}
