-- Sesión del día (1, 2 o 3) de cada finalización, y los índices que usa
-- GET /api/stats/me/events. Diseño en el spec del 2026-09-24.
--
-- NULL = sin sesión: todas las filas anteriores y la app vieja, que no la
-- envía.
ALTER TABLE exercise_completions
  ADD COLUMN session smallint CHECK (session BETWEEN 1 AND 3);
ALTER TABLE training_completions
  ADD COLUMN session smallint CHECK (session BETWEEN 1 AND 3);

-- Los índices de 0001 empiezan por (user_id, exercise_id/training_id): no
-- sirven para "todas las finalizaciones de un usuario desde tal fecha".
CREATE INDEX exercise_completions_user_time_idx
  ON exercise_completions (user_id, completed_at);
CREATE INDEX training_completions_user_time_idx
  ON training_completions (user_id, completed_at);
