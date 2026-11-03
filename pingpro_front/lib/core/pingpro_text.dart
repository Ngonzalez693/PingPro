// Tipografías de la app con el color de su rol: el mismo estilo sirve en
// modo claro y oscuro. Se leen con `context.text` (ver app_theme.dart).
//
// Los "Black" son para texto sobre tarjetas claras y los otros sobre el fondo
// de la pantalla; en modo claro los dos son oscuros, pero no del mismo rol.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

class PingProText {
  final PingProColors colors;

  const PingProText(this.colors);

  TextStyle get title => TextStyle(color: colors.onPage, fontSize: 24, fontWeight: FontWeight.bold);

  TextStyle get titleBlack => TextStyle(color: colors.onCard, fontSize: 24, fontWeight: FontWeight.bold);

  TextStyle get subTitle => TextStyle(color: colors.onPage, fontSize: 20, fontWeight: FontWeight.bold);

  TextStyle get subTitleBlack => TextStyle(color: colors.onCard, fontSize: 20, fontWeight: FontWeight.bold);

  TextStyle get buttons => TextStyle(color: colors.onBrandFill, fontSize: 16, fontWeight: FontWeight.bold);

  TextStyle get paragraph => TextStyle(color: colors.onPage, fontSize: 16);

  TextStyle get paragraphBlack => TextStyle(color: colors.onCard, fontSize: 16);

  TextStyle get aditional => TextStyle(color: colors.onCard, fontSize: 14);

  // Subtítulo gris bajo un título, p. ej. qué muestra una gráfica.
  TextStyle get caption => TextStyle(color: colors.muted, fontSize: 14);

  // Solo para el nombre de la app: Anta es la tipografía de marca, no de UI.
  TextStyle get brandTitle => TextStyle(fontFamily: 'Anta', color: colors.brand, fontSize: 28);

  TextStyle get loginRegister => TextStyle(color: colors.softText, fontWeight: FontWeight.bold);
}
