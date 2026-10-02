import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';

void main() {
  Future<void> pumpPill(WidgetTester tester, VoidCallback onTap) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChoicePill(label: 'Diario', selected: false, onTap: onTap),
      ),
    ));
  }

  testWidgets('enseña su etiqueta', (tester) async {
    await pumpPill(tester, () {});

    expect(find.text('Diario'), findsOneWidget);
  });

  testWidgets('tocarla avisa una vez', (tester) async {
    var taps = 0;
    await pumpPill(tester, () => taps++);

    await tester.tap(find.text('Diario'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
