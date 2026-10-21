import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/pull_to_refresh.dart';

void main() {
  Future<int Function()> pump(WidgetTester tester, Widget Function() list) async {
    var refreshes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PullToRefresh(
          onRefresh: () async => refreshes++,
          child: list(),
        ),
      ),
    ));
    return () => refreshes;
  }

  testWidgets('tirar hacia abajo desde arriba vuelve a cargar', (tester) async {
    final refreshes = await pump(
      tester,
      () => ListView(children: [for (var i = 0; i < 30; i++) ListTile(title: Text('fila $i'))]),
    );

    await tester.fling(find.text('fila 0'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshes(), 1);
  });

  // Con poco contenido la lista no tiene scroll propio: sin forzarlo, el gesto
  // no llegaría al indicador.
  testWidgets('también con una lista corta que no llena la pantalla', (tester) async {
    final refreshes = await pump(
      tester,
      () => ListView(physics: PullToRefresh.physics, children: const [ListTile(title: Text('única'))]),
    );

    await tester.fling(find.text('única'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshes(), 1);
  });
}
