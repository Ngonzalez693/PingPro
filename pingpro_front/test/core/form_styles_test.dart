import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/form_styles.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

void main() {
  // Con el foco el campo no debe cambiar a los colores propios de Material.
  testWidgets('en claro los campos llevan contorno, también con el foco', (tester) async {
    for (final palette in [PingProColors.dark, PingProColors.light]) {
      late InputDecoration decoration;
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: Builder(builder: (context) {
          decoration = formInputDecoration(context, 'Nombre');
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      final expected = outlinedFieldBorder(palette, 16);
      expect(decoration.border, expected);
      expect(decoration.enabledBorder, expected);
      expect(decoration.focusedBorder, expected);
    }
  });
}
