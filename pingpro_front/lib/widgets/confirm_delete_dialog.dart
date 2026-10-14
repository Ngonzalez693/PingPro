// Confirmación antes de borrar algo que no se puede recuperar desde la app:
// un ejercicio, un entrenamiento o una repetición ya hecha. También confirma
// repetir un ejercicio ya hecho en la sesión y crear un ejercicio o un
// entrenamiento igual a uno que ya existe, acciones poco habituales.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si el usuario pulsa el botón de confirmar
/// (`confirmLabel`, "Eliminar" por defecto).
Future<bool> confirmDelete(
  BuildContext context, {
  required String message,
  String confirmLabel = 'Eliminar',
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
