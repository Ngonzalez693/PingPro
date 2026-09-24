// Selector de la sesión del día (1, 2 o 3). Solo pinta: la sesión elegida y
// qué hacer al tocar llegan de fuera (CurrentSession).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/session_progress.dart';
import 'package:pingpro_front/core/text_styles.dart';

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
          Expanded(child: _buildChip(session)),
        ],
      ],
    );
  }

  Widget _buildChip(int session) {
    final isSelected = session == selected;
    return GestureDetector(
      onTap: () => onSelected(session),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secundary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text('Sesión $session', style: TextStyles.buttons),
      ),
    );
  }
}
