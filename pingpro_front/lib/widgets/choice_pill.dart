// Píldora de opción con el estilo de la app: la elegida en `primary`, el resto
// en `secundary`. Es la pieza de las pestañas de filtro (Ejercicios,
// Entrenamientos), de LabeledTabs y de SessionSelector.
//
// Se achica al presionarla y el color cambia con una transición corta, así
// al elegir otra opción la nueva se enciende mientras la anterior se apaga.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';

class ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final TextStyle textStyle;

  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
    this.textStyle = TextStyles.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.secundary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}
