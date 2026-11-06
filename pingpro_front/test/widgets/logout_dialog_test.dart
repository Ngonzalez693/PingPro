import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/widgets/logout_dialog.dart';

void main() {
  // El diálogo y su botón "Volver" son blancos en claro: sin contorno el botón
  // no se distingue del diálogo.
  testWidgets('en claro el diálogo y Volver llevan contorno y en oscuro no', (tester) async {
    for (final palette in [PingProColors.dark, PingProColors.light]) {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(palette),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLogoutDialog(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final side = surfaceOutlineSide(palette);
      final dialogShape = tester.widget<AlertDialog>(find.byType(AlertDialog)).shape as RoundedRectangleBorder;
      expect(dialogShape.side, side ?? BorderSide.none);
      final back = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Volver'));
      expect(back.style!.side?.resolve({}), side);

      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
    }
  });
}
