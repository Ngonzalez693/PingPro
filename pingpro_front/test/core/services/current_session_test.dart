import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/current_session.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

void main() {
  late DateTime now;
  late CurrentSession current;

  // Un día con la sesión 2 ya usada: la sesión por defecto es la 2.
  final usedTwoToday = StatsEvents(trainingCompletions: [
    TrainingCompletionEvent(trainingId: 't1', completedAt: DateTime(2026, 9, 16, 9), session: 2, duration: 30),
  ]);

  setUp(() {
    now = DateTime(2026, 9, 16, 17);
    current = CurrentSession.withClock(() => now);
  });

  test('sin elección usa la sesión por defecto del historial', () {
    expect(current.sessionFor(const StatsEvents()), 1);
    expect(current.sessionFor(usedTwoToday), 2);
  });

  test('una elección manda sobre la sesión por defecto ese mismo día', () {
    current.choose(3);

    expect(current.sessionFor(usedTwoToday), 3);
  });

  test('al día siguiente la elección ya no vale', () {
    current.choose(3);
    now = DateTime(2026, 9, 17, 8);

    expect(current.sessionFor(const StatsEvents()), 1);
  });

  test('elegir avisa a quien escucha', () {
    var notified = 0;
    current.addListener(() => notified++);

    current.choose(2);

    expect(notified, 1);
  });

  test('rechaza una sesión fuera de 1..3', () {
    expect(() => current.choose(4), throwsArgumentError);
    expect(() => current.choose(0), throwsArgumentError);
  });

  test('reset olvida la elección del usuario anterior', () {
    current.choose(3);

    current.reset();

    expect(current.sessionFor(const StatsEvents()), 1);
  });
}
