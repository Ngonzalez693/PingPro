// Desglose de la pantalla de detalle de estadísticas: qué se ha practicado y
// qué toca reforzar en el periodo elegido. Funciones puras sobre los eventos
// de StatsState; el periodo y "ahora" llegan como parámetros para probarlas.
import 'package:pingpro_front/core/exercise_options.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/exercise_model.dart';
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

class ExerciseCount {
  final ExerciseModel exercise;
  final int count;

  const ExerciseCount({required this.exercise, required this.count});
}

class NeglectedExercise {
  final ExerciseModel exercise;
  // null = nunca hecho.
  final int? daysSince;

  const NeglectedExercise({required this.exercise, required this.daysSince});
}

/// Los más repetidos del periodo. Solo ejercicios que siguen existiendo: el
/// nombre sale de ExercisesState y el de un borrado ya no está.
List<ExerciseCount> topExercises(
  List<ExerciseCompletionEvent> completions,
  List<ExerciseModel> exercises, {
  int limit = 5,
}) {
  final byId = {for (final e in exercises) e.id: e};
  final counts = <String, int>{};
  for (final c in completions) {
    if (byId.containsKey(c.exerciseId)) counts[c.exerciseId] = (counts[c.exerciseId] ?? 0) + 1;
  }
  final ranked = [
    for (final e in counts.entries) ExerciseCount(exercise: byId[e.key]!, count: e.value),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.exercise.name.compareTo(b.exercise.name);
    });
  return ranked.take(limit).toList();
}

/// Los que más tiempo llevan sin hacerse, sobre la última finalización de
/// siempre (`completedAt`), no solo la del periodo: "descuidado" es de toda
/// la historia.
List<NeglectedExercise> neglectedExercises(
  List<ExerciseModel> exercises, {
  DateTime? now,
  int limit = 5,
}) {
  final today = _startOfDay(now ?? DateTime.now());
  final ranked = [...exercises]..sort(_byNeglect);
  return [
    for (final e in ranked.take(limit))
      NeglectedExercise(exercise: e, daysSince: _daysSince(e.completedAt, today)),
  ];
}

String neglectLabel(int? daysSince) {
  if (daysSince == null) return 'nunca';
  if (daysSince == 0) return 'hoy';
  if (daysSince == 1) return 'hace 1 día';
  return 'hace $daysSince días';
}

int _byNeglect(ExerciseModel a, ExerciseModel b) {
  final aDone = a.completedAt;
  final bDone = b.completedAt;
  if (aDone == null && bDone == null) return a.name.compareTo(b.name);
  if (aDone == null) return -1;
  if (bDone == null) return 1;
  return aDone.compareTo(bDone);
}

// Redondeando horas y no con inDays: entre dos medianoches con un cambio de
// horario en medio hay 23 o 25 horas.
int? _daysSince(DateTime? when, DateTime today) {
  if (when == null) return null;
  return (today.difference(_startOfDay(when.toLocal())).inHours / 24).round();
}
