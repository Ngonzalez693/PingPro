import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/stats_series.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

StatsEvents _eventsWith(String createdId) => StatsEvents(created: [
  CreatedEvent(kind: CreatedKind.exercise, id: createdId, createdAt: DateTime(2026, 9, 16)),
]);

ExerciseCompletionEvent _exerciseCompletion(String id) => ExerciseCompletionEvent(
  exerciseId: id,
  completedAt: DateTime(2026, 9, 24),
  session: 1,
  category: 'Ataque',
  hits: const [1],
  rotations: const [2],
  deleted: false,
);

TrainingCompletionEvent _trainingCompletion(String id) => TrainingCompletionEvent(
  trainingId: id,
  completedAt: DateTime(2026, 9, 24),
  session: 1,
  duration: 30,
);

StatsEvents _fullEvents(String suffix) => StatsEvents(
  exerciseCompletions: [_exerciseCompletion('ex-$suffix')],
  trainingCompletions: [_trainingCompletion('tr-$suffix')],
  created: _eventsWith('c-$suffix').created,
);

void main() {
  // _safeNotify() consulta SchedulerBinding.instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load guarda los eventos y los pide desde el inicio de la ventana de 6 meses', () async {
    final requested = <DateTime>[];
    final state = StatsState.withFetcher((from) async {
      requested.add(from);
      return _eventsWith('x');
    });

    await state.load();

    expect(state.loadedOnce, isTrue);
    expect(state.error, isNull);
    expect(state.events.created.single.id, 'x');
    expect(requested, [statsWindowStart()]);
  });

  test('un segundo load sin force no vuelve a pedir', () async {
    var calls = 0;
    final state = StatsState.withFetcher((_) async {
      calls++;
      return const StatsEvents();
    });

    await state.load();
    await state.load();

    expect(calls, 1);
  });

  test('si falla guarda el error y sigue sin marcar como cargado', () async {
    final state = StatsState.withFetcher((_) async => throw Exception('sin red'));

    await state.load();

    expect(state.error, contains('sin red'));
    expect(state.loadedOnce, isFalse);
    expect(state.events.created, isEmpty);
  });

  test('refresh durante una carga repite la carga al terminar', () async {
    final first = Completer<StatsEvents>();
    var calls = 0;
    final state = StatsState.withFetcher((_) {
      calls++;
      return calls == 1 ? first.future : Future.value(_eventsWith('nuevo'));
    });

    final loading = state.load();
    await state.refresh();
    first.complete(_eventsWith('viejo'));
    await loading;

    expect(calls, 2);
    expect(state.events.created.single.id, 'nuevo');
  });

  test('reset durante una carga descarta el resultado del usuario anterior', () async {
    final pending = Completer<StatsEvents>();
    final state = StatsState.withFetcher((_) => pending.future);

    final loading = state.load();
    state.reset();
    pending.complete(_eventsWith('del anterior'));
    await loading;

    expect(state.events.created, isEmpty);
    expect(state.loadedOnce, isFalse);
  });

  test('load tras reset con una carga vieja en curso pide los datos del usuario nuevo', () async {
    final stale = Completer<StatsEvents>();
    var calls = 0;
    final state = StatsState.withFetcher((_) {
      calls++;
      return calls == 1 ? stale.future : Future.value(_eventsWith('nuevo'));
    });

    final loading = state.load();
    state.reset();
    await state.load();

    expect(calls, 2);
    expect(state.events.created.single.id, 'nuevo');
    expect(state.loadedOnce, isTrue);

    stale.complete(_eventsWith('viejo'));
    await loading;

    expect(state.events.created.single.id, 'nuevo');
    expect(state.isLoading, isFalse);
  });

  test('addExerciseCompletion añade el evento y conserva las otras listas', () async {
    final state = StatsState.withFetcher((_) async => _fullEvents('server'));
    await state.load();

    state.addExerciseCompletion(_exerciseCompletion('local'));

    expect(state.events.exerciseCompletions.map((e) => e.exerciseId), ['ex-server', 'local']);
    expect(state.events.trainingCompletions.single.trainingId, 'tr-server');
    expect(state.events.created.single.id, 'c-server');
  });

  test('addTrainingCompletion añade el evento y conserva las otras listas', () async {
    final state = StatsState.withFetcher((_) async => _fullEvents('server'));
    await state.load();

    state.addTrainingCompletion(_trainingCompletion('local'));

    expect(state.events.trainingCompletions.map((e) => e.trainingId), ['tr-server', 'local']);
    expect(state.events.exerciseCompletions.single.exerciseId, 'ex-server');
    expect(state.events.created.single.id, 'c-server');
  });

  test('un refresh tras añadir finalizaciones las sustituye por las del servidor', () async {
    var calls = 0;
    final state = StatsState.withFetcher((_) async {
      calls++;
      return _fullEvents(calls == 1 ? 'antes' : 'despues');
    });
    await state.load();

    state.addExerciseCompletion(_exerciseCompletion('local'));
    state.addTrainingCompletion(_trainingCompletion('local'));
    await state.refresh();

    expect(state.events.exerciseCompletions.single.exerciseId, 'ex-despues');
    expect(state.events.trainingCompletions.single.trainingId, 'tr-despues');
    expect(state.events.created.single.id, 'c-despues');
  });

  group('deshacer en local', () {
    ExerciseCompletionEvent exerciseAt(String id, int hour) => ExerciseCompletionEvent(
      exerciseId: id,
      completedAt: DateTime(2026, 9, 24, hour),
      session: 1,
      category: 'Técnico',
      hits: const [],
      rotations: const [],
      deleted: false,
    );

    TrainingCompletionEvent trainingAt(String id, int hour) =>
        TrainingCompletionEvent(trainingId: id, completedAt: DateTime(2026, 9, 24, hour), session: 1, duration: 30);

    test('removeLatestExerciseCompletion quita solo la más reciente de ese ejercicio', () async {
      final state = StatsState.withFetcher((_) async => StatsEvents(exerciseCompletions: [
        exerciseAt('e1', 9),
        exerciseAt('e1', 18),
        exerciseAt('e1', 12),
        exerciseAt('e2', 20),
      ]));
      await state.load();

      state.removeLatestExerciseCompletion('e1');

      expect(
        [for (final e in state.events.exerciseCompletions) '${e.exerciseId}@${e.completedAt.hour}'],
        ['e1@9', 'e1@12', 'e2@20'],
      );
    });

    test('removeLatestTrainingCompletion quita solo la más reciente de ese entrenamiento', () async {
      final state = StatsState.withFetcher((_) async => StatsEvents(trainingCompletions: [
        trainingAt('t1', 9),
        trainingAt('t1', 18),
        trainingAt('t2', 20),
      ]));
      await state.load();

      state.removeLatestTrainingCompletion('t1');

      expect(
        [for (final e in state.events.trainingCompletions) '${e.trainingId}@${e.completedAt.hour}'],
        ['t1@9', 't2@20'],
      );
    });

    test('sin finalizaciones de ese id no cambia nada', () async {
      final state = StatsState.withFetcher((_) async => _fullEvents('server'));
      await state.load();

      state.removeLatestExerciseCompletion('otro');
      state.removeLatestTrainingCompletion('otro');

      expect(state.events.exerciseCompletions.single.exerciseId, 'ex-server');
      expect(state.events.trainingCompletions.single.trainingId, 'tr-server');
    });
  });
}
