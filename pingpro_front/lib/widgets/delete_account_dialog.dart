// Diálogo de "Eliminar cuenta" de Configuración.
//
// Pide la contraseña: confirma que quien borra es el dueño y sirve para la
// re-autenticación que Firebase exige en operaciones sensibles. Como en
// Cambiar contraseña, los errores se muestran dentro sin cerrarlo, y no se
// puede cerrar mientras borra: si se cerrara a medias, quien lo abrió no
// sabría que la cuenta ya no existe.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

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
      style: context.text.paragraphBlack,
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
      // Deshabilitado mientras borra: sigue rojo para que se vea el indicador.
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.danger,
        disabledBackgroundColor: context.colors.danger,
      ),
      onPressed: _isDeleting ? null : _onDeletePressed,
      child: _isDeleting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onDanger),
            )
          : Text('Eliminar', style: context.text.buttons.copyWith(color: context.colors.onDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: context.colors.softFill,
        title: Text('Eliminar cuenta', style: context.text.subTitleBlack),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Se borrarán tu cuenta, tus ejercicios y entrenamientos, tus '
              'favoritos y tu historial de estadísticas. El catálogo de PingPro '
              'no se toca. Esta acción no se puede deshacer.',
              style: context.text.paragraphBlack,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: context.text.paragraphBlack),
          ),
          _buildDeleteButton(),
        ],
      ),
    );
  }
}
