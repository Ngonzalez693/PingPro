import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/widgets/profile_details_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    VoidCallback onEditName, {
    PingProColors colors = PingProColors.dark,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(colors),
      home: Scaffold(
        body: ProfileDetailsCard(name: 'Nicolás', email: 'nico@mail.com', onEditName: onEditName),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('enseña el nombre y el correo', (tester) async {
    await pumpCard(tester, () {});

    expect(find.text('Nicolás'), findsOneWidget);
    expect(find.text('nico@mail.com'), findsOneWidget);
  });

  testWidgets('tocar la fila del nombre abre la edición', (tester) async {
    var taps = 0;
    await pumpCard(tester, () => taps++);

    await tester.tap(find.text('Nicolás'));
    await tester.tap(find.byIcon(Icons.edit));

    expect(taps, 2);
  });

  // El correo es el de la cuenta: no se edita desde aquí.
  testWidgets('tocar el correo no abre la edición', (tester) async {
    var taps = 0;
    await pumpCard(tester, () => taps++);

    await tester.tap(find.text('nico@mail.com'));

    expect(taps, 0);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('en claro la tarjeta lleva contorno y en oscuro no', (tester) async {
    for (final colors in [PingProColors.dark, PingProColors.light]) {
      await pumpCard(tester, () {}, colors: colors);

      final card = tester.widget<Container>(find.byType(Container).first).decoration as BoxDecoration;
      expect(card.color, colors.panel);
      expect(card.border, surfaceOutline(colors));
    }
  });
}
