// Botón circular "+" de la mesa: un punto de golpeo del editor de secuencias.
//
// Solo apariencia: no recibe gestos. El editor escucha los arrastres en todo el
// lienzo y decide con core/table_geometry.dart (originAt) si empezaron sobre
// uno de estos botones. Así la flecha puede seguir al dedo fuera del botón.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class PlusButton extends StatelessWidget {
  /// Diámetro. Lo usa el editor para centrar el botón en su punto de la mesa.
  static const size = 28.0;

  const PlusButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.widgetGrayBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add,
        color: AppColors.textWhite,
        size: 20,
      ),
    );
  }
}
