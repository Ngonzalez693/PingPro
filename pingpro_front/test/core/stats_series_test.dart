import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/stats_series.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

// Miércoles 16 de septiembre de 2026, fijo para no depender del día de la prueba.
final _now = DateTime(2026, 9, 16, 14, 30);

ExerciseCompletionEvent _exercise(DateTime at) => ExerciseCompletionEvent(
  exerciseId: 'e1',
  completedAt: at,
  session: null,
  category: 'Técnico',
  hits: const [1],
  rotations: const [2],
  deleted: false,
);

TrainingCompletionEvent _training(DateTime at) =>
    TrainingCompletionEvent(trainingId: 't1', completedAt: at, session: 1, duration: 30);

CreatedEvent _created(DateTime at) => CreatedEvent(kind: CreatedKind.exercise, id: 'x', createdAt: at);

void main() {
  group('statsWindowStart', () {
    test('es el primer día del mes más viejo del periodo mensual (6 meses)', () {
      expect(statsWindowStart(now: _now), DateTime(2026, 4, 1));
    });
  });

  group('buildStatSeries', () {
    test('cada repetición cuenta: dos finalizaciones el mismo día suman 2', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise(DateTime(2026, 9, 16, 9)),
        _exercise(DateTime(2026, 9, 16, 18)),
      ]);

      final series = buildStatSeries(events, StatPeriod.daily, now: _now);

      expect(series.of(StatType.exercises), [0, 0, 0, 0, 0, 0, 2]);
      expect(series.totalOf(StatType.exercises), 2);
    });

    test('"Creados" cuenta lo creado en su día', () {
      final events = StatsEvents(created: [_created(DateTime(2026, 9, 15, 10))]);

      final series = buildStatSeries(events, StatPeriod.daily, now: _now);

      expect(series.of(StatType.created), [0, 0, 0, 0, 0, 1, 0]);
      expect(series.totalOf(StatType.created), 1);
    });

    test('total suma las tres series por cubo', () {
      final events = StatsEvents(
        exerciseCompletions: [_exercise(DateTime(2026, 9, 16, 9))],
        trainingCompletions: [_training(DateTime(2026, 9, 16, 10))],
        created: [_created(DateTime(2026, 9, 10, 10))],
      );

      final series = buildStatSeries(events, StatPeriod.daily, now: _now);

      expect(series.total, [1, 0, 0, 0, 0, 0, 2]);
    });

    test('lo anterior al primer cubo no cuenta', () {
      final events = StatsEvents(exerciseCompletions: [_exercise(DateTime(2026, 9, 9, 23))]);

      final series = buildStatSeries(events, StatPeriod.daily, now: _now);

      expect(series.totalOf(StatType.exercises), 0);
    });

    test('agrupa por semana y por mes con las etiquetas de stats_buckets', () {
      final events = StatsEvents(trainingCompletions: [
        _training(DateTime(2026, 9, 14, 8)),
        _training(DateTime(2026, 8, 3, 8)),
      ]);

      final weekly = buildStatSeries(events, StatPeriod.weekly, now: _now);
      final monthly = buildStatSeries(events, StatPeriod.monthly, now: _now);

      expect(weekly.labels, hasLength(8));
      expect(weekly.labels.last, '14 Sep');
      expect(weekly.of(StatType.trainings).last, 1);
      expect(monthly.labels, ['Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep']);
      expect(monthly.of(StatType.trainings), [0, 0, 0, 0, 1, 1]);
    });

    test('sin eventos todo es cero', () {
      final series = buildStatSeries(const StatsEvents(), StatPeriod.daily, now: _now);

      expect(series.total, List.filled(7, 0));
      expect(series.labels, hasLength(7));
    });
  });
}
