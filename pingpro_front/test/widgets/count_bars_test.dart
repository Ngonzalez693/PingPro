import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';
import 'package:pingpro_front/widgets/count_bars.dart';

void main() {
  testWidgets('enseña cada fila con su conteo y marca lo que hay que reforzar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CountBars(
          title: 'Por categoría',
          entries: [
            CountEntry(label: 'Footwork', count: 4, reinforce: false),
            CountEntry(label: 'Táctico', count: 0, reinforce: true),
          ],
        ),
      ),
    ));

    expect(find.text('Por categoría'), findsOneWidget);
    expect(find.text('Footwork'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('a reforzar'), findsOneWidget);
  });

  testWidgets('en claro la tarjeta lleva contorno y en oscuro no', (tester) async {
    for (final palette in [PingProColors.dark, PingProColors.light]) {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: const Scaffold(
          body: CountBars(title: 'Por categoría', entries: [CountEntry(label: 'Footwork', count: 4, reinforce: false)]),
        ),
      ));
      await tester.pumpAndSettle();

      final card = tester.widget<Container>(find.byType(Container).first).decoration as BoxDecoration;
      expect(card.border, surfaceOutline(palette));
    }
  });
}
