// Confirmación de cierre de sesión (antes vivía en Editar perfil).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

/// Devuelve true solo si el usuario confirma "Sí, salir".
Future<bool> showLogoutDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Quieres cerrar sesión?',
            textAlign: TextAlign.center,
            style: dialogContext.text.paragraphBlack,
          ),
          const SizedBox(height: 24),
          _dialogButton(
            label: Text('Sí, salir', style: dialogContext.text.buttons),
            color: dialogContext.colors.brandFill,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
          const SizedBox(height: 12),
          _dialogButton(
            label: Text('Volver', style: dialogContext.text.paragraphBlack),
            color: dialogContext.colors.card,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

Widget _dialogButton({required Widget label, required Color color, required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: onPressed,
      child: label,
    ),
  );
}
