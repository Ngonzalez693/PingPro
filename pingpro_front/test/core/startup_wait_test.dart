import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/startup_wait.dart';

// testWidgets corre con un reloj falso: tester.pump(d) adelanta el tiempo sin
// esperar de verdad, también para Future.delayed y timeout.
const _min = Duration(milliseconds: 1500);
const _max = Duration(seconds: 6);

void main() {
  Future<bool Function()> start(Future<void> work) async {
    var done = false;
    unawaited(waitForStartup(work, min: _min, max: _max).then((_) => done = true));
    return () => done;
  }

  testWidgets('si el trabajo termina enseguida, espera hasta el mínimo', (tester) async {
    final done = await start(Future.value());

    await tester.pump(_min - const Duration(milliseconds: 1));
    expect(done(), isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(done(), isTrue);
  });

  testWidgets('entre el mínimo y el máximo, termina cuando termina el trabajo', (tester) async {
    final work = Completer<void>();
    final done = await start(work.future);

    await tester.pump(const Duration(seconds: 3));
    expect(done(), isFalse);

    work.complete();
    await tester.pump();
    expect(done(), isTrue);
  });

  // Como AuthWrapper: Future.wait da un Future<List<void>> aunque se declare
  // Future<void>, y timeout comprueba su callback contra el tipo real.
  testWidgets('acepta un Future.wait de varias cargas', (tester) async {
    final load = Completer<void>();
    final Future<void> work = Future.wait([load.future]);
    final done = await start(work);

    await tester.pump(_min);
    expect(done(), isFalse);

    load.complete();
    await tester.pump();
    expect(done(), isTrue);
  });

  testWidgets('un Future.wait colgado también termina en el máximo', (tester) async {
    final Future<void> work = Future.wait([Completer<void>().future]);
    final done = await start(work);

    await tester.pump(_max);
    expect(done(), isTrue);
  });

  testWidgets('si el trabajo tarda demasiado, termina en el máximo', (tester) async {
    final done = await start(Completer<void>().future);

    await tester.pump(_max - const Duration(milliseconds: 1));
    expect(done(), isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(done(), isTrue);
  });
}
