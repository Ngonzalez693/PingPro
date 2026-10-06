// Diálogo de "Cambiar contraseña" de Configuración.
//
// Como en el de recuperar contraseña, los errores se muestran dentro, sin
// cerrarlo, para corregir y reintentar; el aviso de éxito lo da quien lo abre.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si la contraseña se cambió.
Future<bool> showChangePasswordDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => const ChangePasswordDialog(),
  );
  return changed ?? false;
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  bool _isSaving = false;
  String? _error;

  Future<void> _onSavePressed() async {
    final invalid = validateNewPassword(_newCtrl.text, _repeatCtrl.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await AuthService().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _showError(passwordChangeErrorMessage(e.code));
    } catch (e) {
      debugPrint('changePassword error: $e');
      _showError(passwordChangeErrorMessage(''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _error = message;
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  Widget _buildField(TextEditingController controller, String hint, {String? errorText}) {
    return TextField(
      controller: controller,
      enabled: !_isSaving,
      obscureText: true,
      style: TextStyles.paragraphBlack,
      decoration: InputDecoration(hintText: hint, errorText: errorText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.widgetBackground,
      title: const Text('Cambiar contraseña', style: TextStyles.subTitleBlack),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildField(_currentCtrl, 'Contraseña actual'),
          const SizedBox(height: 8),
          _buildField(_newCtrl, 'Nueva contraseña'),
          const SizedBox(height: 8),
          _buildField(_repeatCtrl, 'Repetir nueva contraseña', errorText: _error),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyles.paragraphBlack),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSaving ? null : _onSavePressed,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textBlack),
                )
              : const Text('Guardar', style: TextStyles.buttons),
        ),
      ],
    );
  }
}
