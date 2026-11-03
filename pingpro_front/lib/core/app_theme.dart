// Tema de la app y acceso corto a sus colores y tipografías desde cualquier
// widget: `context.colors.page`, `context.text.title`.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';

ThemeData buildAppTheme(PingProColors colors) {
  return ThemeData(scaffoldBackgroundColor: colors.page, extensions: [colors]);
}

extension PingProThemeContext on BuildContext {
  // Sin la extensión (un widget montado suelto en un test, sin MaterialApp)
  // se usa la paleta oscura, que es la de siempre.
  PingProColors get colors => Theme.of(this).extension<PingProColors>() ?? PingProColors.dark;

  PingProText get text => PingProText(colors);
}
