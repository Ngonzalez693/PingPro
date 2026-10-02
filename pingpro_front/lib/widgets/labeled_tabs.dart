// Pestañas de ancho repartido, hechas con ChoicePill. Las usan el periodo del resumen y del
// detalle de estadísticas y el conmutador Golpe/Rotación. Solo pinta: la
// opción elegida y qué hacer al tocar llegan de fuera.
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';

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
          Expanded(
            child: ChoicePill(
              label: options[i].$2,
              selected: options[i].$1 == selected,
              onTap: () => onSelected(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}
