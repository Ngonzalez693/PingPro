import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

// Servicio falso: devuelve siempre el mismo ejercicio y apunta lo que se le
// pide. `implements` no obliga a tocar el servicio real; lo que el store no
// usa cae en noSuchMethod.
class _FakeExercisesService implements ExercisesService {
  final completions = <(String, bool, int?)>[];
  var fetches = 0;
  var creates = 0;
  bool failCompletion = false;

  @override
  Future<List<ExerciseModel>> fetchAllMergedWithUserState() async {
    fetches++;
    return [
      ExerciseModel(
        id: 'e1',
        name: 'Topspin',
        category: 'Técnico',
        image: '',
        description: '',
        sequence: [SequenceStep(hit: 4, rotation: 2, zone: 3, direction: 6, side: 1)],
      ),
    ];
  }

  @override
  Future<void> setCompleted({required String id, required bool completed, int? session}) async {
    if (failCompletion) throw Exception('sin red');
    completions.add((id, completed, session));
  }

  @override
  Future<String> create(ExerciseDraft draft) async {
    creates++;
    return 'nuevo';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExerciseCompletionEvent _event(String id, DateTime at) => ExerciseCompletionEvent(
  exerciseId: id,
  completedAt: at,
  session: 1,
  category: 'Técnico',
  hits: const [],
  rotations: const [],
  deleted: false,
);

void main() {
  // safeNotify() (mixin SafeNotify) consulta SchedulerBinding.instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeExercisesService service;
  late StatsState stats;
  late ExercisesState store;
  late int statsFetches;

  // El fetch de estadísticas nunca termina: así lo que el store añade o quita
  // en local se puede comprobar antes de que una recarga lo sustituya.
  setUp(() async {
    service = _FakeExercisesService();
    statsFetches = 0;
    stats = StatsState.withFetcher((_) {
      statsFetches++;
      return Completer<StatsEvents>().future;
    });
    store = ExercisesState.forTest(service: service, stats: stats);
    await store.load();
  });

  test('setCompleted envía la sesión, marca la última vez y añade la repetición a las estadísticas', () async {
    await store.setCompleted('e1', true, session: 2);

    expect(service.completions, [('e1', true, 2)]);
    expect(store.getById('e1')!.completedAt, isNotNull);
    final event = stats.events.exerciseCompletions.single;
    expect(event.exerciseId, 'e1');
    expect(event.session, 2);
    expect(event.hits, [4]);
    expect(statsFetches, 1);
  });

  test('si el servidor falla, deshace el cambio, relanza el error y no toca las estadísticas', () async {
    service.failCompletion = true;

    await expectLater(store.setCompleted('e1', true, session: 1), throwsException);

    expect(store.getById('e1')!.completedAt, isNull);
    expect(stats.events.exerciseCompletions, isEmpty);
    expect(statsFetches, 0);
  });

  test('deshacer envía completed false, quita la última repetición y recarga la lista', () async {
    stats.addExerciseCompletion(_event('e1', DateTime(2026, 9, 25, 9)));
    stats.addExerciseCompletion(_event('e1', DateTime(2026, 9, 25, 18)));
    final fetchesBefore = service.fetches;

    await store.setCompleted('e1', false);

    expect(service.completions, [('e1', false, null)]);
    expect(stats.events.exerciseCompletions.single.completedAt, DateTime(2026, 9, 25, 9));
    expect(service.fetches, fetchesBefore + 1);
    expect(statsFetches, 1);
  });

  test('crear recarga la lista y las estadísticas', () async {
    final fetchesBefore = service.fetches;

    await store.create(const ExerciseDraft(name: 'Nuevo', category: 'Técnico', image: '', sequence: []));

    expect(service.creates, 1);
    expect(service.fetches, fetchesBefore + 1);
    expect(statsFetches, 1);
  });
}
