// Contador circular con icono y número (ejercicios / entrenamientos /
// creados). Se usa suelto en Perfil y agrupado en SummaryIconRow.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pingpro_front/core/app_theme.dart';

class SummaryIcon extends StatelessWidget {
  final String assetPath;
  final int count;
  final String label;

  const SummaryIcon({
    super.key,
    required this.assetPath,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Círculo con icono y número dentro
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.card,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 7,
                child: SvgPicture.asset(
                assetPath,
                width: 28,
                height: 28,
                ),
              ),
              Positioned(
                bottom: 1,
                child: Text(
                  '$count',
                  style: context.text.titleBlack,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Debajo del círculo, sobre la pantalla: el estilo de los botones, con el
        // color del texto de la pantalla (el negro de botón no se veía en oscuro).
        Text(label, style: context.text.buttons.copyWith(color: context.colors.onPage)),
      ],
    );
  }
}
