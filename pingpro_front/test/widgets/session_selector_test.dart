import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/session_selector.dart';

void main() {
  Future<List<int>> tapChip(WidgetTester tester, String label) async {
    final chosen = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SessionSelector(selected: 1, onSelected: chosen.add)),
    ));
    await tester.tap(find.text(label));
    return chosen;
  }

  testWidgets('enseña las tres sesiones', (tester) async {
    await tapChip(tester, 'Sesión 1');

    expect(find.text('Sesión 1'), findsOneWidget);
    expect(find.text('Sesión 2'), findsOneWidget);
    expect(find.text('Sesión 3'), findsOneWidget);
  });

  testWidgets('tocar una sesión la elige', (tester) async {
    expect(await tapChip(tester, 'Sesión 3'), [3]);
  });
}
