import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/session_progress.dart';
import 'package:pingpro_front/models/stats_events_model.dart';
import 'package:pingpro_front/models/training_model.dart';

// Miércoles 16 de septiembre de 2026 a media tarde, fijo.
final _now = DateTime(2026, 9, 16, 17);
final _today = DateTime(2026, 9, 16, 9);
final _yesterday = DateTime(2026, 9, 15, 20);

ExerciseCompletionEvent _exercise(String id, DateTime at, int? session) => ExerciseCompletionEvent(
  exerciseId: id,
  completedAt: at,
  session: session,
  category: 'Técnico',
  hits: const [],
  rotations: const [],
  deleted: false,
);

TrainingCompletionEvent _training(String id, DateTime at, int? session) =>
    TrainingCompletionEvent(trainingId: id, completedAt: at, session: session, duration: 30);

TrainingModel _trainingModel(String id, List<String> exerciseIds) => TrainingModel(
  id: id,
  name: id,
  category: 'Grado',
  image: '',
  description: '',
  exerciseIds: exerciseIds,
  duration: 30,
);

void main() {
  group('defaultSession', () {
    test('sin nada hoy es la sesión 1', () {
      final events = StatsEvents(exerciseCompletions: [_exercise('e1', _yesterday, 3)]);

      expect(defaultSession(events, now: _now), 1);
    });

    test('es la sesión más alta usada hoy, en ejercicios o entrenamientos', () {
      final events = StatsEvents(
        exerciseCompletions: [_exercise('e1', _today, 1)],
        trainingCompletions: [_training('t1', _today, 2)],
      );

      expect(defaultSession(events, now: _now), 2);
    });

    test('las finalizaciones sin sesión no cuentan', () {
      final events = StatsEvents(exerciseCompletions: [_exercise('e1', _today, null)]);

      expect(defaultSession(events, now: _now), 1);
    });
  });

  group('isExerciseDoneInSession', () {
    test('solo cuenta hoy y en la misma sesión', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise('e1', _today, 1),
        _exercise('e2', _yesterday, 2),
        _exercise('e3', _today, null),
      ]);

      expect(isExerciseDoneInSession('e1', events, 1, now: _now), isTrue);
      expect(isExerciseDoneInSession('e1', events, 2, now: _now), isFalse);
      expect(isExerciseDoneInSession('e2', events, 2, now: _now), isFalse);
      expect(isExerciseDoneInSession('e3', events, 1, now: _now), isFalse);
    });
  });

  group('trainingDoneFlags', () {
    test('marca cada posición hecha hoy en la sesión', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise('e1', _today, 2),
        _exercise('e3', _today, 1),
      ]);

      expect(trainingDoneFlags(['e1', 'e2', 'e3'], events, 2, now: _now), [true, false, false]);
    });

    test('un ejercicio repetido necesita una finalización por aparición', () {
      final once = StatsEvents(exerciseCompletions: [_exercise('e1', _today, 1)]);
      final twice = StatsEvents(exerciseCompletions: [
        _exercise('e1', _today, 1),
        _exercise('e1', _today, 1),
      ]);

      expect(trainingDoneFlags(['e1', 'e2', 'e1'], once, 1, now: _now), [true, false, false]);
      expect(trainingDoneFlags(['e1', 'e2', 'e1'], twice, 1, now: _now), [true, false, true]);
    });

    test('un entrenamiento vacío no tiene posiciones', () {
      expect(trainingDoneFlags(const [], const StatsEvents(), 1, now: _now), isEmpty);
    });
  });

  group('isTrainingDoneInSession', () {
    test('solo cuenta hoy y en la misma sesión', () {
      final events = StatsEvents(trainingCompletions: [
        _training('t1', _today, 1),
        _training('t2', _yesterday, 1),
      ]);

      expect(isTrainingDoneInSession('t1', events, 1, now: _now), isTrue);
      expect(isTrainingDoneInSession('t1', events, 2, now: _now), isFalse);
      expect(isTrainingDoneInSession('t2', events, 1, now: _now), isFalse);
    });
  });

  test('isSameDay compara el día del calendario, no 24 horas', () {
    expect(isSameDay(DateTime(2026, 9, 16, 0, 5), DateTime(2026, 9, 16, 23, 55)), isTrue);
    expect(isSameDay(DateTime(2026, 9, 15, 23, 55), DateTime(2026, 9, 16, 0, 5)), isFalse);
  });

  group('canUndoInSession', () {
    test('se puede si la última repetición es de hoy y de esa sesión', () {
      final events = StatsEvents(exerciseCompletions: [
        _exercise('e1', _yesterday, 1),
        _exercise('e1', _today, 1),
      ]);

      expect(canUndoInSession('e1', events, 1, now: _now), isTrue);
      expect(canUndoInSession('e1', events, 2, now: _now), isFalse);
    });

    test('no se puede si la última es de otra sesión, aunque haya una de esta antes', () {
      // El backend deshace siempre la última: deshacer desde la sesión 1
      // borraría la de la sesión 2.
      final events = StatsEvents(exerciseCompletions: [
        _exercise('e1', DateTime(2026, 9, 16, 9), 1),
        _exercise('e1', DateTime(2026, 9, 16, 15), 2),
      ]);

      expect(canUndoInSession('e1', events, 1, now: _now), isFalse);
      expect(canUndoInSession('e1', events, 2, now: _now), isTrue);
    });

    test('no se puede si la última es de ayer, sin sesión o no hay ninguna', () {
      expect(canUndoInSession('e1', StatsEvents(exerciseCompletions: [_exercise('e1', _yesterday, 1)]), 1, now: _now),
          isFalse);
      expect(canUndoInSession('e1', StatsEvents(exerciseCompletions: [_exercise('e1', _today, null)]), 1, now: _now),
          isFalse);
      expect(canUndoInSession('e1', const StatsEvents(), 1, now: _now), isFalse);
    });
  });

  group('trainingsToReopen', () {
    test('reabre el entrenamiento completado hoy en la sesión al que ya le falta un ejercicio', () {
      // Estado después de deshacer e2: queda e1 hecho, falta e2.
      final events = StatsEvents(
        exerciseCompletions: [_exercise('e1', _today, 1)],
        trainingCompletions: [_training('t1', _today, 1)],
      );

      final reopen = trainingsToReopen('e2', events, [_trainingModel('t1', ['e1', 'e2'])], 1, now: _now);

      expect(reopen, ['t1']);
    });

    test('no toca entrenamientos sin ese ejercicio, de otra sesión o que siguen completos', () {
      final events = StatsEvents(
        exerciseCompletions: [
          _exercise('e1', _today, 1),
          _exercise('e2', _today, 1),
        ],
        trainingCompletions: [
          _training('sin-e3', _today, 1),
          _training('otra-sesion', _today, 2),
          _training('sigue-completo', _today, 1),
        ],
      );
      final trainings = [
        _trainingModel('sin-e3', ['e1']),
        _trainingModel('otra-sesion', ['e3']),
        _trainingModel('sigue-completo', ['e1', 'e2']),
        _trainingModel('no-completado', ['e3']),
      ];

      expect(trainingsToReopen('e3', events, trainings, 1, now: _now), isEmpty);
      expect(trainingsToReopen('e1', events, trainings, 1, now: _now), isEmpty);
    });
  });
}
