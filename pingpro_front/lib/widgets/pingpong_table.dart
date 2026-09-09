// Mesa de tenis de mesa vista desde arriba, con los puntos de golpeo.
// Es el lienzo del flujo de creación de ejercicios.
//
// LIMITACIÓN: mide 280x400 px fijos y los botones se colocan con coordenadas
// absolutas calculadas a ojo (`index * 62.6`). No es responsive: en pantallas
// pequeñas se desborda y en grandes queda diminuta. Para terminar la pantalla
// de creación habría que rehacerla con LayoutBuilder y posiciones relativas.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/widgets/pingpong_top_buttons.dart';
import 'package:pingpro_front/widgets/pingpong_bottom_buttons.dart';

class PingPongTable extends StatelessWidget {
  const PingPongTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGray, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Línea central horizontal
          Positioned(
            left: 0,
            right: 0,
            top: 200,
            child: Container(
              height: 2,
              color: AppColors.textGray,
            ),
          ),
          // Línea central vertical
          Positioned(
            top: 0,
            bottom: 0,
            left: 140,
            child: Container(
              width: 2,
              color: AppColors.textGray,
            ),
          ),
          // Botones superiores e inferiores
          const PingPongTopButtons(),
          const PingPongBottomButtons(),
        ],
      ),
    );
  }
}
