// Qué cuenta como hecho "hoy en la sesión elegida", a partir del historial
// del servidor (StatsState). Funciones puras: el día y la sesión llegan como
// parámetros para poder probarlas.
//
// Las finalizaciones sin sesión (anteriores a las sesiones, o de la app
// vieja) nunca cuentan para el progreso de hoy.
import 'package:pingpro_front/models/stats_events_model.dart';

/// Sesiones que se pueden elegir en un día.
const sessionNumbers = [1, 2, 3];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// La sesión más alta usada hoy, o la 1 si hoy no hay nada: al volver a abrir
/// la app a media tarde se sigue en la sesión en curso.
int defaultSession(StatsEvents events, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final usedToday = [
    for (final e in events.exerciseCompletions)
      if (isSameDay(e.completedAt, today)) e.session,
    for (final e in events.trainingCompletions)
      if (isSameDay(e.completedAt, today)) e.session,
  ].whereType<int>();
  return usedToday.fold(1, (highest, session) => session > highest ? session : highest);
}

bool isExerciseDoneInSession(String exerciseId, StatsEvents events, int session, {DateTime? now}) =>
    _exerciseCompletionsIn(events, session, now ?? DateTime.now())
        .any((e) => e.exerciseId == exerciseId);

/// Por cada posición del entrenamiento, si ese ejercicio está hecho hoy en la
/// sesión. Las finalizaciones se reparten en orden: un ejercicio que aparece
/// dos veces necesita dos para marcar las dos posiciones.
List<bool> trainingDoneFlags(List<String> exerciseIds, StatsEvents events, int session, {DateTime? now}) {
  final remaining = <String, int>{};
  for (final e in _exerciseCompletionsIn(events, session, now ?? DateTime.now())) {
    remaining[e.exerciseId] = (remaining[e.exerciseId] ?? 0) + 1;
  }
  return [for (final id in exerciseIds) _takeOne(remaining, id)];
}

bool isTrainingDoneInSession(String trainingId, StatsEvents events, int session, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return events.trainingCompletions.any((e) =>
      e.trainingId == trainingId && e.session == session && isSameDay(e.completedAt, today));
}

Iterable<ExerciseCompletionEvent> _exerciseCompletionsIn(StatsEvents events, int session, DateTime day) =>
    events.exerciseCompletions.where((e) => e.session == session && isSameDay(e.completedAt, day));

bool _takeOne(Map<String, int> remaining, String id) {
  final left = remaining[id] ?? 0;
  if (left == 0) return false;
  remaining[id] = left - 1;
  return true;
}
