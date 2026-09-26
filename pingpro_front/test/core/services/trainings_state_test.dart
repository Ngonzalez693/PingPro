import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/services/training_services.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/models/stats_events_model.dart';
import 'package:pingpro_front/models/training_model.dart';

// Servicio falso: un solo entrenamiento, y apunta lo que se le pide. Lo que
// el store no usa cae en noSuchMethod.
class _FakeTrainingsService implements TrainingsService {
  final completions = <(String, bool, int?)>[];
  var fetches = 0;
  var deletes = 0;
  bool failCompletion = false;

  @override
  Future<List<TrainingModel>> fetchAllWithUserState() async {
    fetches++;
    return [
      TrainingModel(
        id: 't1',
        name: 'Calentamiento',
        category: 'Grado',
        image: '',
        description: '',
        exerciseIds: const ['e1', 'e2'],
        duration: 40,
      ),
    ];
  }

  @override
  Future<void> setCompleted(String id, bool completed, {int? session}) async {
    if (failCompletion) throw Exception('sin red');
    completions.add((id, completed, session));
  }

  @override
  Future<void> delete(String id, {required bool own}) async {
    deletes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrainingCompletionEvent _event(String id, DateTime at) =>
    TrainingCompletionEvent(trainingId: id, completedAt: at, session: 1, duration: 40);

void main() {
  // safeNotify() (mixin SafeNotify) consulta SchedulerBinding.instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTrainingsService service;
  late StatsState stats;
  late TrainingsState store;
  late int statsFetches;

  // El fetch de estadísticas nunca termina: así lo que el store añade o quita
  // en local se puede comprobar antes de que una recarga lo sustituya.
  setUp(() async {
    service = _FakeTrainingsService();
    statsFetches = 0;
    stats = StatsState.withFetcher((_) {
      statsFetches++;
      return Completer<StatsEvents>().future;
    });
    store = TrainingsState.forTest(service: service, stats: stats);
    await store.load();
  });

  test('setCompleted envía la sesión y añade la finalización con su duración', () async {
    await store.setCompleted('t1', true, session: 3);

    expect(service.completions, [('t1', true, 3)]);
    expect(store.getById('t1')!.completedAt, isNotNull);
    final event = stats.events.trainingCompletions.single;
    expect(event.trainingId, 't1');
    expect(event.session, 3);
    expect(event.duration, 40);
    expect(statsFetches, 1);
  });

  test('si el servidor falla, deshace el cambio, relanza el error y no toca las estadísticas', () async {
    service.failCompletion = true;

    await expectLater(store.setCompleted('t1', true, session: 1), throwsException);

    expect(store.getById('t1')!.completedAt, isNull);
    expect(stats.events.trainingCompletions, isEmpty);
    expect(statsFetches, 0);
  });

  test('deshacer envía completed false, quita la última finalización y recarga la lista', () async {
    stats.addTrainingCompletion(_event('t1', DateTime(2026, 9, 25, 9)));
    stats.addTrainingCompletion(_event('t1', DateTime(2026, 9, 25, 18)));
    final fetchesBefore = service.fetches;

    await store.setCompleted('t1', false);

    expect(service.completions, [('t1', false, null)]);
    expect(stats.events.trainingCompletions.single.completedAt, DateTime(2026, 9, 25, 9));
    expect(service.fetches, fetchesBefore + 1);
    expect(statsFetches, 1);
  });

  test('eliminar recarga la lista y las estadísticas', () async {
    final fetchesBefore = service.fetches;

    await store.delete(store.getById('t1')!);

    expect(service.deletes, 1);
    expect(service.fetches, fetchesBefore + 1);
    expect(statsFetches, 1);
  });
}
