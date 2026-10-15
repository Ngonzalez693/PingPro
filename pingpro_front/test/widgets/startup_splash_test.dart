import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/startup_wait.dart';
import 'package:pingpro_front/widgets/startup_splash.dart';

void main() {
  // La pelota rebota sin fin: aquí se usa pump con tiempos, nunca pumpAndSettle.
  testWidgets('muestra la marca y avisa solo cuando la carga terminó', (tester) async {
    final load = Completer<void>();
    var loadCalls = 0;
    var ready = 0;
    await tester.pumpWidget(MaterialApp(
      home: StartupSplash(
        load: () {
          loadCalls++;
          return load.future;
        },
        onReady: () => ready++,
      ),
    ));

    expect(find.text('PingPro'), findsOneWidget);
    expect(loadCalls, 1);

    await tester.pump(startupMinimum * 2);
    expect(ready, 0);

    load.complete();
    await tester.pump();
    expect(ready, 1);
  });

  testWidgets('con la carga colgada, avisa igual al llegar al máximo', (tester) async {
    var ready = 0;
    await tester.pumpWidget(MaterialApp(
      home: StartupSplash(load: () => Completer<void>().future, onReady: () => ready++),
    ));

    await tester.pump(startupMaximum);
    expect(ready, 1);
  });
}
