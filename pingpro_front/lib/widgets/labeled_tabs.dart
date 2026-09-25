// Pestañas de ancho repartido con el estilo de la app: la elegida en
// `primary`, el resto en `secundary`. Las usan el periodo del resumen y del
// detalle de estadísticas y el conmutador Golpe/Rotación. Solo pinta: la
// opción elegida y qué hacer al tocar llegan de fuera.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class LabeledTabs<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const LabeledTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildTab(options[i].$1, options[i].$2)),
        ],
      ],
    );
  }

  Widget _buildTab(T value, String label) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: value == selected ? AppColors.primary : AppColors.secundary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyles.buttons),
      ),
    );
  }
}
