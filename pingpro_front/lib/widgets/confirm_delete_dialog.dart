// Confirmación antes de eliminar un ejercicio o un entrenamiento. Desde la app
// no se puede deshacer, así que siempre se pregunta.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si el usuario pulsa "Eliminar".
Future<bool> confirmDelete(BuildContext context, {required String message}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.widgetBackground,
      content: Text(message, style: TextStyles.paragraphBlack),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar', style: TextStyles.paragraphBlack),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Eliminar', style: TextStyles.buttons),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
