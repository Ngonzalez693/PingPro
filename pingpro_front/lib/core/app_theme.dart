// Tema de la app y acceso corto a sus colores y tipografías desde cualquier
// widget: `context.colors.page`, `context.text.title`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';

// Las hojas y los menús toman su fondo de aquí y no al abrirse: así un cambio
// de tema con uno abierto también les llega.
ThemeData buildAppTheme(PingProColors colors) {
  return ThemeData(
    scaffoldBackgroundColor: colors.page,
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.tabBar),
    popupMenuTheme: PopupMenuThemeData(color: colors.softFill),
    extensions: [colors],
  );
}

// Iconos de la barra de estado según el fondo: oscuros sobre la crema, claros
// sobre negro. Solo la barra de arriba: la de botones de Android es del sistema.
SystemUiOverlayStyle overlayStyleFor(PingProColors colors) {
  final lightPage = colors.page.computeLuminance() > 0.5;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: lightPage ? Brightness.dark : Brightness.light,
    statusBarBrightness: lightPage ? Brightness.light : Brightness.dark,
  );
}

// Los SVG de assets/icons vienen pintados con los colores del tema oscuro:
// lima los de acento (`_selected`) y blanco el resto. Teñirlos con un filtro
// les quita suavizado en los bordes, así que solo se tiñen cuando el tema pide
// otro color, como en claro.
ColorFilter? iconTint(PingProColors colors, {required bool accent}) {
  final wanted = accent ? colors.brand : colors.onPage;
  final drawn = accent ? PingProColors.dark.brand : PingProColors.dark.onPage;
  return wanted == drawn ? null : ColorFilter.mode(wanted, BlendMode.srcIn);
}

extension PingProThemeContext on BuildContext {
  // Sin la extensión (un widget montado suelto en un test, sin MaterialApp)
  // se usa la paleta oscura, que es la de siempre.
  PingProColors get colors => Theme.of(this).extension<PingProColors>() ?? PingProColors.dark;

  PingProText get text => PingProText(colors);
}
