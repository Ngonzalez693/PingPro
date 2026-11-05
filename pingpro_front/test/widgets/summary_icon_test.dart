import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      // Cambiar de tema funde los colores: hay que esperar a que termine.
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('Ejercicios')).style!.color, palette.onPage);
    }
  });
  // Los SVG vienen blancos o lima: sobre el círculo blanco del modo claro el
  // blanco desaparece, así que se tiñen con los colores del tema.
  testWidgets('en claro el icono se tiñe y en oscuro se dibuja tal cual', (tester) async {
    Future<ColorFilter?> tintWith(PingProColors palette) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: const Scaffold(
          body: SummaryIcon(assetPath: 'assets/icons/training_unselected.svg', count: 0, label: 'Entrenamientos'),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter;
    }

    expect(await tintWith(PingProColors.dark), isNull);
    expect(await tintWith(PingProColors.light), ColorFilter.mode(PingProColors.light.onPage, BlendMode.srcIn));
  });
}
