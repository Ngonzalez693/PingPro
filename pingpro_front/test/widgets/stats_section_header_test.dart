import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/stats_section_header.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, VoidCallback onSeeDetail) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatsSectionHeader(
          caption: 'Tu actividad de los últimos 7 días',
          onSeeDetail: onSeeDetail,
        ),
      ),
    ));
  }

  testWidgets('enseña el título, la descripción y Ver detalle', (tester) async {
    await pumpHeader(tester, () {});

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Tu actividad de los últimos 7 días'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
  });

  testWidgets('Ver detalle avisa una vez', (tester) async {
    var taps = 0;
    await pumpHeader(tester, () => taps++);

    await tester.tap(find.text('Ver detalle'));

    expect(taps, 1);
  });

  // El botón va a la derecha, a la altura de la descripción.
  testWidgets('Ver detalle queda a la derecha de la descripción', (tester) async {
    await pumpHeader(tester, () {});

    final caption = tester.getRect(find.text('Tu actividad de los últimos 7 días'));
    final button = tester.getRect(find.text('Ver detalle'));
    expect(button.left, greaterThan(caption.right));
    expect(button.center.dy, closeTo(caption.center.dy, 12));
  });
}
