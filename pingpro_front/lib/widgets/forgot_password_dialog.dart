// Diálogo de "¿Olvidaste tu contraseña?" del login.
//
// Los errores se muestran dentro del diálogo, sin cerrarlo, para que el
// usuario corrija el email y reintente; el aviso de éxito lo da el login.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/email_validation.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Devuelve true solo si se pidió el correo de recuperación.
Future<bool> showForgotPasswordDialog(
  BuildContext context, {
  String initialEmail = '',
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail),
  );
  return sent ?? false;
}

class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  bool _isSending = false;
  String? _error;

  Future<void> _onSendPressed() async {
    final email = _emailCtrl.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = 'Email no válido');
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _showError(passwordResetErrorMessage(e.code));
    } catch (e) {
      debugPrint('sendPasswordReset error: $e');
      _showError(passwordResetErrorMessage(''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _error = message;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.widgetBackground,
      title: const Text('Recuperar contraseña', style: TextStyles.subTitleBlack),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Te enviaremos un enlace para elegir una contraseña nueva.',
            style: TextStyles.paragraphBlack,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            enabled: !_isSending,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            style: TextStyles.paragraphBlack,
            decoration: InputDecoration(hintText: 'Email', errorText: _error),
            onSubmitted: (_) => _onSendPressed(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyles.paragraphBlack),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSending ? null : _onSendPressed,
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textBlack,
                  ),
                )
              : const Text('Enviar', style: TextStyles.buttons),
        ),
      ],
    );
  }
}
