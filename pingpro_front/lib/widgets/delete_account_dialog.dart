// Diálogo de "Eliminar cuenta" de Configuración.
//
// Pide la contraseña: confirma que quien borra es el dueño y sirve para la
// re-autenticación que Firebase exige en operaciones sensibles. Como en
// Cambiar contraseña, los errores se muestran dentro sin cerrarlo, y no se
// puede cerrar mientras borra: si se cerrara a medias, quien lo abrió no
// sabría que la cuenta ya no existe.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si la cuenta se eliminó (y la sesión ya está cerrada).
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const DeleteAccountDialog(),
  );
  return deleted ?? false;
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  Future<void> _onDeletePressed() async {
    // Sin contraseña no vale la pena gastar uno de los intentos que Firebase
    // limita.
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña');
      return;
    }
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await AuthService().deleteAccount(_passwordCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _showError(accountDeletionErrorMessage(e.code));
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      _showError(accountDeletionErrorMessage(''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _error = message;
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      enabled: !_isDeleting,
      obscureText: true,
      style: TextStyles.paragraphBlack,
      decoration: InputDecoration(
        hintText: 'Contraseña actual',
        errorText: _error,
        // Los mensajes de error no caben en una línea dentro del diálogo.
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
      onPressed: _isDeleting ? null : _onDeletePressed,
      child: _isDeleting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textBlack),
            )
          : const Text('Eliminar', style: TextStyles.buttons),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: AppColors.widgetBackground,
        title: const Text('Eliminar cuenta', style: TextStyles.subTitleBlack),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Se borrarán tu cuenta, tus ejercicios y entrenamientos, tus '
              'favoritos y tu historial de estadísticas. El catálogo de PingPro '
              'no se toca. Esta acción no se puede deshacer.',
              style: TextStyles.paragraphBlack,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyles.paragraphBlack),
          ),
          _buildDeleteButton(),
        ],
      ),
    );
  }
}
