import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
