import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class ExerciseDone extends StatelessWidget {
  final VoidCallback onFinalize;

  const ExerciseDone({super.key, required this.onFinalize});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.widgetGrayBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      content: Text(
        '¡Excelente!\na seguir entrenando',
        style: TextStyles.titleBlack,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: onFinalize,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textBlack,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Finalizar', style: TextStyles.buttons),
        ),
      ],
    );
  }
}
