import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/widgets/summary_icon.dart';

void main() {
  // La etiqueta va debajo del círculo, sobre la pantalla: con el color de los
  // botones salía negra sobre el negro del modo oscuro y no se veía.
  testWidgets('la etiqueta usa el color del texto de la pantalla', (tester) async {
    for (final palette in [PingProColors.dark, PingProColors.light]) {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: const Scaffold(
          body: SummaryIcon(assetPath: 'assets/icons/exercise_unselected.svg', count: 3, label: 'Ejercicios'),
        ),
      ));

      expect(tester.widget<Text>(find.text('Ejercicios')).style!.color, palette.onPage);
    }
  });
}
