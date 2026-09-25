import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

// Miércoles 16 de septiembre de 2026, fijo.
final _now = DateTime(2026, 9, 16, 14, 30);

ExerciseCompletionEvent _exercise({
  String id = 'e1',
  DateTime? at,
  int? session,
  String category = 'Técnico',
  List<int> hits = const [],
  List<int> rotations = const [],
}) => ExerciseCompletionEvent(
  exerciseId: id,
  completedAt: at ?? DateTime(2026, 9, 16, 9),
  session: session,
  category: category,
  hits: hits,
  rotations: rotations,
  deleted: false,
);

TrainingCompletionEvent _training({DateTime? at, int? session, int? duration = 30}) =>
    TrainingCompletionEvent(
      trainingId: 't1',
      completedAt: at ?? DateTime(2026, 9, 16, 10),
      session: session,
      duration: duration,
    );

List<String> _reinforced(List<CountEntry> entries) =>
    [for (final e in entries) if (e.reinforce) e.label];

ExerciseModel _model(String id, String name, {DateTime? completedAt}) => ExerciseModel(
  id: id,
  name: name,
  category: 'Técnico',
  image: '',
  description: '',
  sequence: const [],
  completedAt: completedAt,
);

void main() {
  group('eventsInPeriod', () {
    test('deja fuera lo anterior al primer cubo del periodo', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise(at: DateTime(2026, 9, 9, 23)),
        _exercise(at: DateTime(2026, 9, 10, 0, 1)),
      ]);

      final daily = eventsInPeriod(events, StatPeriod.daily, now: _now);
      final monthly = eventsInPeriod(events, StatPeriod.monthly, now: _now);

      expect(daily.exerciseCompletions, hasLength(1));
      expect(monthly.exerciseCompletions, hasLength(2));
    });
  });

  group('countByCategory', () {
    test('cuenta las cuatro categorías en orden y marca la más baja con empates', () {
      final entries = countByCategory([
        _exercise(category: 'Técnico'),
        _exercise(category: 'Técnico'),
        _exercise(category: 'Footwork'),
      ]);

      expect([for (final e in entries) e.label], ['Footwork', 'Técnico', 'Táctico', 'Estrategia']);
      expect([for (final e in entries) e.count], [1, 2, 0, 0]);
      expect(_reinforced(entries), ['Táctico', 'Estrategia']);
    });

    test('sin actividad no marca nada para reforzar', () {
      final entries = countByCategory(const []);

      expect(entries.every((e) => e.count == 0 && !e.reinforce), isTrue);
    });

    test('una categoría desconocida no rompe ni cuenta', () {
      final entries = countByCategory([_exercise(category: 'Ataque')]);

      expect(entries.fold(0, (sum, e) => sum + e.count), 0);
    });
  });

  group('countByStroke', () {
    test('cuenta cada golpe una vez por ejercicio completado y deja fuera los Libre', () {
      final entries = countByStroke([
        _exercise(hits: [1, 4]),
        _exercise(hits: [1, 8]),
      ], StrokeAspect.hit);

      final byLabel = {for (final e in entries) e.label: e.count};
      expect(byLabel['Forehand'], 2);
      expect(byLabel['Forehand Flick'], 1);
      expect(byLabel.containsKey('Libre'), isFalse);
      expect(byLabel.containsKey('Hasta que se caiga'), isFalse);
      expect(entries, hasLength(10));
    });

    test('marca las 3 más bajas incluyendo empates', () {
      final entries = countByStroke([
        _exercise(rotations: [1, 2, 3, 4, 5]),
        _exercise(rotations: [1, 2, 3, 4]),
        _exercise(rotations: [1, 2, 3]),
      ], StrokeAspect.rotation);

      // Back Spin 3, Topspin 3, Side Spin Derecha 3, Side Spin Izquierda 2,
      // Drive 1, Liftado 0: el umbral es el tercer conteo más bajo (2).
      expect(entries, hasLength(6));
      expect(_reinforced(entries), ['Side Spin Izquierda', 'Drive', 'Liftado']);
    });
  });

  group('currentStreak', () {
    StatsEvents onDays(List<int> days) => StatsEvents(exerciseCompletions: [
      for (final day in days) _exercise(at: DateTime(2026, 9, day, 18)),
    ]);

    test('cuenta los días seguidos hasta hoy', () {
      expect(currentStreak(onDays([16, 15, 14, 12]), now: _now), 3);
    });

    test('si hoy aún no hay nada, cuenta hasta ayer', () {
      expect(currentStreak(onDays([15, 14]), now: _now), 2);
    });

    test('sin ayer ni hoy la racha es 0', () {
      expect(currentStreak(onDays([13]), now: _now), 0);
    });

    test('los entrenamientos también cuentan', () {
      final events = StatsEvents(trainingCompletions: [_training(at: DateTime(2026, 9, 16, 8))]);

      expect(currentStreak(events, now: _now), 1);
    });
  });

  test('activeDays cuenta días distintos con alguna finalización', () {
    final events = StatsEvents(
      exerciseCompletions: [
        _exercise(at: DateTime(2026, 9, 16, 9)),
        _exercise(at: DateTime(2026, 9, 16, 19)),
      ],
      trainingCompletions: [_training(at: DateTime(2026, 9, 14, 9))],
    );

    expect(activeDays(events), 2);
  });

  test('minutesTrained suma la duración de los entrenamientos y null cuenta 0', () {
    final events = StatsEvents(trainingCompletions: [
      _training(duration: 30),
      _training(duration: null),
      _training(duration: 45),
    ]);

    expect(minutesTrained(events), 75);
  });

  group('sessionsPerBucket', () {
    test('cuenta días distintos por sesión en cada cubo', () {
      final events = StatsEvents(
        exerciseCompletions: [
          _exercise(at: DateTime(2026, 9, 16, 9), session: 1),
          _exercise(at: DateTime(2026, 9, 16, 9, 30), session: 1),
          _exercise(at: DateTime(2026, 9, 15, 9)),
        ],
        trainingCompletions: [_training(at: DateTime(2026, 9, 16, 18), session: 2)],
      );

      final series = sessionsPerBucket(events, StatPeriod.daily, now: _now);

      expect(series.keys, sessionKeys);
      expect(series[1], [0, 0, 0, 0, 0, 0, 1]);
      expect(series[2], [0, 0, 0, 0, 0, 0, 1]);
      expect(series[3], List.filled(7, 0));
      expect(series[null], [0, 0, 0, 0, 0, 1, 0]);
    });

    test('en semanal suma los días de la semana', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise(at: DateTime(2026, 9, 14, 9), session: 1),
        _exercise(at: DateTime(2026, 9, 16, 9), session: 1),
      ]);

      expect(sessionsPerBucket(events, StatPeriod.weekly, now: _now)[1]!.last, 2);
    });
  });

  group('topExercises', () {
    test('ordena por repeticiones, solo ejercicios existentes, desempate por nombre', () {
      final exercises = [_model('e1', 'Topspin'), _model('e2', 'Bloqueo'), _model('e3', 'Corte')];
      final completions = [
        _exercise(id: 'e1'), _exercise(id: 'e1'), _exercise(id: 'e1'),
        _exercise(id: 'e2'),
        _exercise(id: 'e3'),
        for (var i = 0; i < 5; i++) _exercise(id: 'borrado'),
      ];

      final top = topExercises(completions, exercises);

      expect([for (final t in top) t.exercise.name], ['Topspin', 'Bloqueo', 'Corte']);
      expect([for (final t in top) t.count], [3, 1, 1]);
    });

    test('respeta el límite', () {
      final exercises = [for (var i = 0; i < 7; i++) _model('e$i', 'Ejercicio $i')];
      final completions = [for (var i = 0; i < 7; i++) _exercise(id: 'e$i')];

      final top = topExercises(completions, exercises);

      expect(top, hasLength(5));
      expect([for (final t in top) t.exercise.name],
          ['Ejercicio 0', 'Ejercicio 1', 'Ejercicio 2', 'Ejercicio 3', 'Ejercicio 4']);
    });
  });

  group('neglectedExercises', () {
    test('primero los nunca hechos por nombre, luego el más antiguo', () {
      final exercises = [
        _model('d', 'Hoy', completedAt: DateTime(2026, 9, 16, 8)),
        _model('c', 'Hace diez', completedAt: DateTime(2026, 9, 6, 20)),
        _model('b', 'Beta'),
        _model('a', 'Alfa'),
      ];

      final neglected = neglectedExercises(exercises, now: _now, limit: 3);

      expect([for (final n in neglected) n.exercise.name], ['Alfa', 'Beta', 'Hace diez']);
      expect([for (final n in neglected) n.daysSince], [null, null, 10]);
    });

    test('el desempate por nombre entre nunca hechos no distingue mayúsculas', () {
      final exercises = [_model('b', 'beta'), _model('a', 'Alfa')];

      final neglected = neglectedExercises(exercises, now: _now);

      expect([for (final n in neglected) n.exercise.name], ['Alfa', 'beta']);
    });

    test('lo hecho hoy son 0 días', () {
      final neglected = neglectedExercises([_model('d', 'Hoy', completedAt: DateTime(2026, 9, 16, 8))], now: _now);

      expect(neglected.single.daysSince, 0);
    });

    test('un completedAt en UTC se cuenta en días del teléfono', () {
      // Justo pasada la medianoche local: en una zona UTC+ esto cae en el día
      // siguiente en UTC, así que sin .toLocal() el conteo saldría mal.
      final neglected = neglectedExercises(
        [_model('c', 'Hace diez', completedAt: DateTime(2026, 9, 7, 0, 30).toUtc())],
        now: _now,
      );

      expect(neglected.single.daysSince, 9);
    });
  });

  test('neglectLabel', () {
    expect(neglectLabel(null), 'nunca');
    expect(neglectLabel(0), 'hoy');
    expect(neglectLabel(1), 'hace 1 día');
    expect(neglectLabel(5), 'hace 5 días');
  });
}
