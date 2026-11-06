// Estilo común de los campos de los formularios de creación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

/// Campo gris claro con esquinas redondeadas, sin borde en oscuro y con el
/// contorno suave en claro.
InputDecoration formInputDecoration(BuildContext context, String hint) {
  final border = outlinedFieldBorder(context.colors, 16);
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: context.colors.card,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
