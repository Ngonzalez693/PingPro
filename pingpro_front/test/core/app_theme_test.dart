import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

final _custom = PingProColors.dark.copyWith(page: const Color(0xFF112233), onPage: const Color(0xFF445566));

void main() {
  // Muchos tests montan un widget suelto, sin MaterialApp: tiene que seguir
  // funcionando y verse como hoy.
  testWidgets('sin tema encima usa la paleta oscura', (tester) async {
    late PingProColors seen;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) {
        seen = context.colors;
        return const SizedBox();
      }),
    ));

    expect(seen, PingProColors.dark);
  });

  testWidgets('lee la paleta del tema', (tester) async {
    late PingProColors seen;
    late Color titleColor;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(_custom),
      home: Builder(builder: (context) {
        seen = context.colors;
        titleColor = context.text.title.color!;
        return const SizedBox();
      }),
    ));

    expect(seen, _custom);
    expect(titleColor, _custom.onPage);
  });

  test('el fondo de las pantallas es el de la paleta', () {
    expect(buildAppTheme(PingProColors.dark).scaffoldBackgroundColor, AppColors.background);
  });
  test('iconos oscuros sobre la crema y claros sobre negro', () {
    final light = overlayStyleFor(PingProColors.light);
    final dark = overlayStyleFor(PingProColors.dark);

    expect(light.statusBarIconBrightness, Brightness.dark);
    expect(dark.statusBarIconBrightness, Brightness.light);
    // La barra de botones de Android es del sistema: no se toca.
    expect(light.systemNavigationBarColor, isNull);
    expect(dark.systemNavigationBarColor, isNull);
  });

  testWidgets('Sistema sigue al teléfono', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    late PingProColors seen;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.light),
      darkTheme: buildAppTheme(PingProColors.dark),
      themeMode: ThemeMode.system,
      home: Builder(builder: (context) {
        seen = context.colors;
        return const SizedBox();
      }),
    ));
    expect(seen, PingProColors.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(seen, PingProColors.light);
  });
  // Si cada hoja o menú pasara su color al abrirse, quedaría fijo aunque el
  // tema cambie con la hoja abierta.
  test('las hojas y los menús toman la paleta del tema', () {
    for (final palette in [PingProColors.dark, PingProColors.light]) {
      final theme = buildAppTheme(palette);

      expect(theme.bottomSheetTheme.backgroundColor, palette.tabBar);
      expect(theme.popupMenuTheme.color, palette.softFill);
    }
  });

  // Un borde transparente de 1 px igual movería el contenido: en oscuro no
  // tiene que haber borde.
  test('en oscuro no hay contorno y en claro es fino y suave', () {
    const dark = PingProColors.dark;
    expect(surfaceOutlineSide(dark), isNull);
    expect(surfaceOutline(dark), isNull);
    expect(outlinedFieldBorder(dark, 12).borderSide, BorderSide.none);

    const light = PingProColors.light;
    expect(surfaceOutlineSide(light), BorderSide(color: light.outline));
    expect(surfaceOutline(light), Border.all(color: light.outline));
    expect(
      outlinedFieldBorder(light, 12),
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: light.outline)),
    );
  });

  test('los diálogos y los menús llevan el contorno solo en claro', () {
    final dark = buildAppTheme(PingProColors.dark);
    expect(dark.dialogTheme.shape, isNull);
    expect(dark.popupMenuTheme.shape, isNull);

    const light = PingProColors.light;
    final theme = buildAppTheme(light);
    final side = BorderSide(color: light.outline);
    expect(theme.dialogTheme.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: side));
    expect(theme.popupMenuTheme.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: side));
  });
}
