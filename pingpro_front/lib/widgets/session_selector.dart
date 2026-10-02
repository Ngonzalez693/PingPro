// Selector de la sesión del día (1, 2 o 3). Solo pinta: la sesión elegida y
// qué hacer al tocar llegan de fuera (CurrentSession).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/session_progress.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';

class SessionSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const SessionSelector({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final session in sessionNumbers) ...[
          if (session != sessionNumbers.first) const SizedBox(width: 8),
          Expanded(
            child: ChoicePill(
              label: 'Sesión $session',
              selected: session == selected,
              onTap: () => onSelected(session),
            ),
          ),
        ],
      ],
    );
  }
}
