import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/pull_to_refresh.dart';

class _Harness {
  final ScrollController controller = ScrollController();
  int refreshes = 0;
  Future<void> Function()? onRefresh;
}

Future<_Harness> _pump(WidgetTester tester, {int rows = 30}) async {
  final h = _Harness();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PullToRefresh(
        onRefresh: () {
          h.refreshes++;
          return h.onRefresh?.call() ?? Future.value();
        },
        child: ListView(
          controller: h.controller,
          physics: PullToRefresh.physics,
          children: [for (var i = 0; i < rows; i++) SizedBox(height: 60, child: Text('fila $i'))],
        ),
      ),
    ),
  ));
  return h;
}

final _spinner = find.byType(CircularProgressIndicator);

// Arrastra en pasos cortos, como un dedo: un solo moveBy grande se lo come
// casi entero el umbral de arrastre.
Future<void> _drag(WidgetTester tester, TestGesture gesture, double dy) async {
  final steps = (dy.abs() / 10).ceil();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, dy / steps));
    await tester.pump();
  }
}

Future<TestGesture> _press(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('tirar hacia abajo desde arriba y soltar vuelve a cargar', (tester) async {
    final h = await _pump(tester);

    await tester.fling(find.text('fila 0'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(h.refreshes, 1);
  });

  testWidgets('también con una lista corta que no llena la pantalla', (tester) async {
    final h = await _pump(tester, rows: 1);

    await tester.fling(find.text('fila 0'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(h.refreshes, 1);
  });

  testWidgets('sin tirar no aparece el indicador', (tester) async {
    await _pump(tester);

    expect(_spinner, findsNothing);
  });

  testWidgets('un tirón corto se suelta sin recargar', (tester) async {
    final h = await _pump(tester);

    final gesture = await _press(tester);
    await _drag(tester, gesture, 60);
    expect(_spinner, findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(h.refreshes, 0);
    expect(_spinner, findsNothing);
  });

  // Lo que pidió el usuario: volver con el dedo primero recoge el indicador y
  // la lista no se mueve hasta que este desaparece.
  testWidgets('al volver hacia arriba la lista no se mueve hasta que el indicador desaparece', (tester) async {
    final h = await _pump(tester);

    final gesture = await _press(tester);
    await _drag(tester, gesture, 120);
    expect(_spinner, findsOneWidget);
    expect(h.controller.offset, 0);

    await _drag(tester, gesture, -60);
    expect(_spinner, findsOneWidget);
    expect(h.controller.offset, 0);

    await _drag(tester, gesture, -200);
    expect(_spinner, findsNothing);
    expect(h.controller.offset, greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.refreshes, 0);
  });

  testWidgets('pasar el punto de recarga y volver por debajo antes de soltar la cancela', (tester) async {
    final h = await _pump(tester);

    final gesture = await _press(tester);
    await _drag(tester, gesture, 300);
    await _drag(tester, gesture, -250);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(h.refreshes, 0);
  });

  testWidgets('el indicador gira mientras recarga y se va al terminar', (tester) async {
    final h = await _pump(tester);
    final load = Completer<void>();
    h.onRefresh = () => load.future;

    final gesture = await _press(tester);
    await _drag(tester, gesture, 300);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    expect(h.refreshes, 1);
    expect(_spinner, findsOneWidget);
    expect(tester.widget<CircularProgressIndicator>(_spinner).value, isNull);

    load.complete();
    await tester.pumpAndSettle();
    expect(_spinner, findsNothing);
  });
}
