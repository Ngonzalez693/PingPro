/**
 * Datos de ejemplo de los contratos. Los comparte cualquier enlace, así que no
 * deben depender de ninguna base de datos.
 */
import type { IExercise } from '../../src/interfaces/models/IExercise';
import type { ITraining } from '../../src/interfaces/models/ITraining';
import type { IModel3D } from '../../src/interfaces/models/IModel3D';
import type { IUser } from '../../src/interfaces/models/IUser';
import { DirectionCode, HitCode, RotationCode, SideCode, ZoneCode } from '../../src/utils/enums';
import type { CatalogFixtures } from './catalogRepository.contract';

export const exerciseFixtures: CatalogFixtures<IExercise> = {
  a: {
    name: 'Topspin cruzado',
    category: 'Técnico',
    image: 'assets/images/exercise_1.jpg',
    description: 'Topspin de derecha a la esquina izquierda',
    sequence: [
      {
        hit: HitCode.FOREHAND,
        rotation: RotationCode.TOPSPIN,
        zone: ZoneCode.LARGO,
        direction: DirectionCode.ESQUINA_IZQUIERDA,
        side: SideCode.ESQUINA_DERECHA,
      },
    ],
  },
  b: {
    name: 'Flick y revés',
    category: 'Táctico',
    image: 'assets/images/exercise_2.jpg',
    sequence: [
      {
        hit: HitCode.BANANA_FLICK,
        rotation: RotationCode.SIDE_SPIN_L,
        zone: ZoneCode.CORTO,
        direction: DirectionCode.MEDIO,
        side: SideCode.MEDIO,
      },
      {
        hit: HitCode.BACKHAND,
        rotation: RotationCode.DRIVE,
        zone: ZoneCode.INTERMEDIO,
        direction: DirectionCode.ESQUINA_DERECHA,
        side: SideCode.MEDIO_IZQUIERDO,
      },
    ],
  },
  patch: { name: 'Topspin cruzado largo', description: 'Ahora al fondo de la mesa' },
};

export const trainingFixtures: CatalogFixtures<ITraining> = {
  a: {
    name: 'Calentamiento',
    category: 'Grado',
    image: 'assets/images/training_1.jpg',
    description: 'Rutina corta para empezar',
    exerciseIds: ['e1', 'e2'],
    duration: 20,
  },
  b: {
    name: 'Ataque',
    category: 'Objetivo',
    image: 'assets/images/training_2.jpg',
    exerciseIds: ['e3'],
    duration: 45,
  },
  patch: { exerciseIds: ['e1', 'e2', 'e3'], duration: 30 },
};

// Con id propio: el catálogo 3D no se crea desde la API, se siembra.
export const model3dFixtures: Record<'older' | 'newer', IModel3D & { id: string }> = {
  older: {
    id: 'forehand-topspin',
    name: 'Forehand Topspin',
    url: 'https://example.com/models/forehand-topspin.glb',
    createdAt: new Date('2026-01-10T10:00:00.000Z'),
    updatedAt: new Date('2026-01-12T08:00:00.000Z'),
  },
  newer: {
    id: 'mov-largo-der-izq',
    name: 'MovLargoDerIzq',
    url: 'https://example.com/models/mov-largo-der-izq.glb',
    createdAt: new Date('2026-02-03T09:30:00.000Z'),
    updatedAt: new Date('2026-02-03T09:30:00.000Z'),
  },
};

// Perfil tal como lo crea el registro (AuthController.signUp), sin el id: el
// id es el uid y lo pone createWithUID.
export const userFixtures: { user: IUser; patch: Partial<IUser> } = {
  user: {
    email: 'ana@test.dev',
    displayName: 'Ana',
    roles: ['user'],
    createdAt: new Date('2026-03-01T12:00:00.000Z'),
    updatedAt: new Date('2026-03-01T12:00:00.000Z'),
  },
  patch: { displayName: 'Ana García', photoURL: 'https://example.com/ana.jpg' },
};
