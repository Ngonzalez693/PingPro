-- Golpes nuevos (Hook 10, Globo 11, Smash 12) y profundidad del jugador en su
-- propio campo. Diseño en el spec del 2026-09-22.
--
-- own_zone usa los mismos valores que zone (1 Corto, 2 Intermedio, 3 Largo,
-- 4 Libre). Los pasos anteriores no la conocen: quedan en 4, "sin especificar".

-- El CHECK de 0001 no tiene nombre explícito; Postgres lo llamó así.
ALTER TABLE exercise_steps DROP CONSTRAINT exercise_steps_hit_check;
ALTER TABLE exercise_steps ADD CONSTRAINT exercise_steps_hit_check CHECK (hit BETWEEN 1 AND 12);

ALTER TABLE exercise_steps
  ADD COLUMN own_zone smallint NOT NULL DEFAULT 4 CHECK (own_zone BETWEEN 1 AND 4);
