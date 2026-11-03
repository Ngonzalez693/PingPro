// Confirmación antes de una acción que no se puede deshacer o que es poco
// habitual: borrar, deshacer una repetición, repetir un ejercicio o crear uno
// igual a otro.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

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
      backgroundColor: dialogContext.colors.softFill,
      content: Text(message, style: dialogContext.text.paragraphBlack),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancelar', style: dialogContext.text.paragraphBlack),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: dialogContext.colors.brandFill),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel, style: dialogContext.text.buttons),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
