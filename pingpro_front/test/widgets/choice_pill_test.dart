import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
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

  // En claro la pastilla sin elegir es blanca sobre la crema: el contorno la
  // separa. La elegida es lima y no lo necesita.
  testWidgets('en claro la pastilla sin elegir lleva contorno y en oscuro no', (tester) async {
    Future<Decoration?> outlineOf(PingProColors palette, {required bool selected}) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: Scaffold(body: ChoicePill(label: 'Diario', selected: selected, onTap: () {})),
      ));
      await tester.pumpAndSettle();
      return tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).foregroundDecoration;
    }

    final light = await outlineOf(PingProColors.light, selected: false) as BoxDecoration;
    expect(light.border, surfaceOutline(PingProColors.light));
    expect(await outlineOf(PingProColors.light, selected: true), isNull);
    expect(await outlineOf(PingProColors.dark, selected: false), isNull);
  });
}
