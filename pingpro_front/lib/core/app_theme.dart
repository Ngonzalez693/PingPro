// Tema de la app y acceso corto a sus colores y tipografías desde cualquier
// widget: `context.colors.page`, `context.text.title`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';

// Las hojas y los menús toman su fondo de aquí y no al abrirse: así un cambio
// de tema con uno abierto también les llega.
//
// Los diálogos y los menús son blancos en claro: llevan el contorno con los
// radios por defecto de Material 3 (28 y 4). En oscuro no se toca su forma.
ThemeData buildAppTheme(PingProColors colors) {
  final outline = surfaceOutlineSide(colors);
  return ThemeData(
    scaffoldBackgroundColor: colors.page,
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.tabBar),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.softFill,
      shape: outline == null ? null : _rounded(4, outline),
    ),
    dialogTheme: DialogThemeData(shape: outline == null ? null : _rounded(28, outline)),
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

RoundedRectangleBorder _rounded(double radius, BorderSide side) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side);

// En oscuro no hay contorno, ni siquiera transparente: un borde de 1 px mueve
// el contenido y oscuro tiene que quedar igual.
BorderSide? surfaceOutlineSide(PingProColors colors) =>
    colors.outline.a == 0 ? null : BorderSide(color: colors.outline);

Border? surfaceOutline(PingProColors colors) {
  final side = surfaceOutlineSide(colors);
  return side == null ? null : Border.fromBorderSide(side);
}

// Va en `border`, `enabledBorder` y `focusedBorder`: con solo `border`, Material
// le pondría sus propios colores al contorno.
OutlineInputBorder outlinedFieldBorder(PingProColors colors, double radius) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: surfaceOutlineSide(colors) ?? BorderSide.none,
  );
}

extension PingProThemeContext on BuildContext {
  // Sin la extensión (un widget montado suelto en un test, sin MaterialApp)
  // se usa la paleta oscura, que es la de siempre.
  PingProColors get colors => Theme.of(this).extension<PingProColors>() ?? PingProColors.dark;

  PingProText get text => PingProText(colors);
}
