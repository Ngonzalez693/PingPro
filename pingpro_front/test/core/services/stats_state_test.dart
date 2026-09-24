import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/stats_series.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

StatsEvents _eventsWith(String createdId) => StatsEvents(created: [
  CreatedEvent(kind: CreatedKind.exercise, id: createdId, createdAt: DateTime(2026, 9, 16)),
]);

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
}
