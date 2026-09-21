// Estilo común de los campos de los formularios de creación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

/// Campo gris claro con esquinas redondeadas y sin borde.
InputDecoration formInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.widgetGrayBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
