import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/labeled_tabs.dart';

void main() {
  Future<void> pumpTabs(WidgetTester tester, ValueChanged<int> onSelected) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LabeledTabs<int>(
          options: const [(1, 'Uno'), (2, 'Dos')],
          selected: 1,
          onSelected: onSelected,
        ),
      ),
    ));
  }

  testWidgets('enseña una pestaña por opción', (tester) async {
    await pumpTabs(tester, (_) {});

    expect(find.text('Uno'), findsOneWidget);
    expect(find.text('Dos'), findsOneWidget);
  });

  testWidgets('tocar una pestaña devuelve su valor', (tester) async {
    final chosen = <int>[];
    await pumpTabs(tester, chosen.add);

    await tester.tap(find.text('Dos'));

    expect(chosen, [2]);
  });
}
