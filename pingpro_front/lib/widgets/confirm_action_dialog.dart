// Confirmación antes de una acción que no se puede deshacer o que es poco
// habitual: borrar, deshacer una repetición, repetir un ejercicio o crear uno
// igual a otro.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si el usuario pulsa el botón de confirmar
/// (`confirmLabel`). Sin valor por defecto: el botón tiene que nombrar la
/// acción concreta.
Future<bool> confirmAction(
  BuildContext context, {
  required String message,
  required String confirmLabel,
}) async {
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
          child: Text(confirmLabel, style: TextStyles.buttons),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
