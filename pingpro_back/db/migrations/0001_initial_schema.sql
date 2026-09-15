-- Esquema inicial de PingPro en Postgres. Diseño y razones en el spec del
-- 2026-09-14 (esquema de Postgres y migración a Supabase).
--
-- Los ids son text: se conservan los de Firestore y los nuevos son UUID.
-- owner_id NULL = contenido del catálogo; con valor = privado de ese usuario.
-- Ejercicios y entrenamientos se borran de forma lógica (deleted_at): las
-- cascadas por exercise_id/training_id solo se disparan al borrar un usuario.

CREATE TABLE users (
  id           text PRIMARY KEY,               -- uid de Firebase Auth
  email        text NOT NULL,
  display_name text,
  photo_url    text,
  roles        text[],
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- Las categorías repiten EXERCISE_CATEGORIES / TRAINING_CATEGORIES de
-- src/utils/constants.ts.
CREATE TABLE exercises (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_id    text REFERENCES users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  category    text NOT NULL
              CHECK (category IN ('Footwork', 'Técnico', 'Táctico', 'Estrategia')),
  image       text NOT NULL,
  description text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz
);
CREATE INDEX exercises_owner_id_idx ON exercises (owner_id);

-- Rangos de src/utils/enums.ts. Añadir un valor a un enum = migración nueva
-- que amplía el CHECK (solo al final, como exige enums.ts).
CREATE TABLE exercise_steps (
  exercise_id text     NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  position    smallint NOT NULL CHECK (position >= 0),
  hit         smallint NOT NULL CHECK (hit BETWEEN 1 AND 9),
  rotation    smallint NOT NULL CHECK (rotation BETWEEN 1 AND 7),
  zone        smallint NOT NULL CHECK (zone BETWEEN 1 AND 4),
  direction   smallint NOT NULL CHECK (direction BETWEEN 1 AND 8),
  side        smallint NOT NULL CHECK (side BETWEEN 1 AND 5),
  PRIMARY KEY (exercise_id, position)
);

CREATE TABLE trainings (
  id          text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_id    text REFERENCES users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  category    text NOT NULL
              CHECK (category IN ('Grado', 'Objetivo', 'Momento', 'Estilo', 'Estructura')),
  image       text NOT NULL,
  description text,
  duration    integer CHECK (duration >= 0),               -- minutos
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz
);
CREATE INDEX trainings_owner_id_idx ON trainings (owner_id);

-- La PK por posición permite repetir un ejercicio dentro del entrenamiento.
CREATE TABLE training_exercises (
  training_id text     NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
  position    smallint NOT NULL CHECK (position >= 0),
  exercise_id text     NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  PRIMARY KEY (training_id, position)
);

-- is_favorite NULL = nunca se tocó (el contrato lo devuelve como ausente).
CREATE TABLE user_exercise_states (
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id text NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  is_favorite boolean,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, exercise_id)
);

-- Historial: una fila por cada vez que se completa. El completedAt de la API
-- es el max(completed_at).
CREATE TABLE exercise_completions (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id  text NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  completed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX exercise_completions_lookup_idx
  ON exercise_completions (user_id, exercise_id, completed_at DESC);

CREATE TABLE user_training_states (
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  training_id text NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, training_id)
);

CREATE TABLE training_completions (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  training_id  text NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
  completed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX training_completions_lookup_idx
  ON training_completions (user_id, training_id, completed_at DESC);

CREATE TABLE models_3d (
  id         text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name       text NOT NULL UNIQUE,     -- llave del mapper de animaciones
  url        text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Sin políticas: anon y authenticated no leen ni escriben nada por la API
-- REST de Supabase. El backend se conecta como dueño de las tablas.
ALTER TABLE users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises            ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_steps       ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_exercises   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_exercise_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_training_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE models_3d            ENABLE ROW LEVEL SECURITY;
