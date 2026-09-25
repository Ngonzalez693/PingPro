// Desglose de la pantalla de detalle de estadísticas: qué se ha practicado y
// qué toca reforzar en el periodo elegido. Funciones puras sobre los eventos
// de StatsState; el periodo y "ahora" llegan como parámetros para probarlas.
import 'package:pingpro_front/core/exercise_options.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

/// Una barra del desglose: qué, cuántas veces y si toca reforzarlo.
class CountEntry {
  final String label;
  final int count;
  final bool reinforce;

  const CountEntry({required this.label, required this.count, required this.reinforce});
}

enum StrokeAspect { hit, rotation }

// Códigos que no son algo concreto que reforzar.
const _freeHits = {HitCode.free, HitCode.untilItFalls};
const _freeRotations = {RotationCode.free};

/// Los eventos del periodo: desde el inicio del primer cubo hasta ahora.
StatsEvents eventsInPeriod(StatsEvents events, StatPeriod period, {DateTime? now}) {
  final from = dateRange(period, now: now).first;
  bool inPeriod(DateTime when) => !when.isBefore(from);
  return StatsEvents(
    exerciseCompletions: events.exerciseCompletions.where((e) => inPeriod(e.completedAt)).toList(),
    trainingCompletions: events.trainingCompletions.where((e) => inPeriod(e.completedAt)).toList(),
    created: events.created.where((e) => inPeriod(e.createdAt)).toList(),
  );
}

List<CountEntry> countByCategory(List<ExerciseCompletionEvent> completions) {
  final counts = {for (final category in exerciseCategories) category: 0};
  for (final completion in completions) {
    final current = counts[completion.category];
    if (current != null) counts[completion.category] = current + 1;
  }
  return _withReinforce([for (final e in counts.entries) (e.key, e.value)], lowest: 1);
}

/// Claves de las series apiladas de sesiones: 1, 2, 3 y null (sin sesión).
const sessionKeys = <int?>[1, 2, 3, null];

/// Días seguidos con alguna finalización hasta hoy, o hasta ayer si hoy aún
/// no hay nada (la racha no se rompe hasta que termina el día).
int currentStreak(StatsEvents events, {DateTime? now}) {
  final days = _activeDates(events);
  final today = _startOfDay(now ?? DateTime.now());
  var day = days.contains(today) ? today : _dayBefore(today);
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = _dayBefore(day);
  }
  return streak;
}

int activeDays(StatsEvents events) => _activeDates(events).length;

int minutesTrained(StatsEvents events) =>
    events.trainingCompletions.fold(0, (sum, e) => sum + (e.duration ?? 0));

/// Por cada sesión, en cuántos días distintos de cada cubo se entrenó en ella.
/// Se cuentan días y no finalizaciones: la gráfica responde "cuántas sesiones
/// hice", no "cuántos ejercicios".
Map<int?, List<int>> sessionsPerBucket(StatsEvents events, StatPeriod period, {DateTime? now}) {
  final buckets = dateRange(period, now: now);
  final daysBySession = {for (final key in sessionKeys) key: <DateTime>{}};
  for (final e in events.exerciseCompletions) {
    daysBySession[e.session]?.add(_startOfDay(e.completedAt));
  }
  for (final e in events.trainingCompletions) {
    daysBySession[e.session]?.add(_startOfDay(e.completedAt));
  }
  return {
    for (final key in sessionKeys) key: bucketCounts(daysBySession[key]!.toList(), buckets, period),
  };
}

Set<DateTime> _activeDates(StatsEvents events) => {
  for (final e in events.exerciseCompletions) _startOfDay(e.completedAt),
  for (final e in events.trainingCompletions) _startOfDay(e.completedAt),
};

// Por calendario y no restando Duration: cruzar un cambio de horario con
// Duration(days: 1) no cae en medianoche (ver stats_buckets.dart).
DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _dayBefore(DateTime day) => DateTime(day.year, day.month, day.day - 1);

List<CountEntry> countByStroke(List<ExerciseCompletionEvent> completions, StrokeAspect aspect) {
  final labels = aspect == StrokeAspect.hit ? hitLabels : rotationLabels;
  final excluded = aspect == StrokeAspect.hit ? _freeHits : _freeRotations;
  final counts = {
    for (final code in labels.keys)
      if (!excluded.contains(code)) code: 0,
  };
  for (final completion in completions) {
    final codes = aspect == StrokeAspect.hit ? completion.hits : completion.rotations;
    for (final code in codes) {
      final current = counts[code];
      if (current != null) counts[code] = current + 1;
    }
  }
  return _withReinforce([for (final e in counts.entries) (labels[e.key]!, e.value)], lowest: 3);
}

/// Marca "a reforzar" todo lo que tenga un conteo ≤ el `lowest`-ésimo más
/// bajo, con empates: si varias cosas están igual de olvidadas, todas lo
/// están. Sin actividad no hay nada con qué comparar y no se marca nada.
List<CountEntry> _withReinforce(List<(String, int)> counts, {required int lowest}) {
  final total = counts.fold(0, (sum, c) => sum + c.$2);
  final sorted = [for (final c in counts) c.$2]..sort();
  final threshold = sorted.isEmpty ? 0 : sorted[(lowest - 1).clamp(0, sorted.length - 1)];
  return [
    for (final c in counts)
      CountEntry(label: c.$1, count: c.$2, reinforce: total > 0 && c.$2 <= threshold),
  ];
}
