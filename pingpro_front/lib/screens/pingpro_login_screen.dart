// Inicio de sesión.
//
// Va directo contra Firebase Auth (AuthService.login), sin pasar por el
// backend. Tras autenticar vuelve a la raíz y es AuthWrapper quien decide la
// pantalla; también mantiene la sesión en los siguientes arranques.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/email_validation.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/widgets/custom_text_field.dart';
import 'package:pingpro_front/widgets/fade_slide_in.dart';
import 'package:pingpro_front/widgets/forgot_password_dialog.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';
import 'package:pingpro_front/widgets/shake_on_error.dart';

class PingproLoginScreen extends StatefulWidget {
  const PingproLoginScreen({super.key});

  @override
  State<PingproLoginScreen> createState() => _PingproLoginScreenState();
}

class _PingproLoginScreenState extends State<PingproLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  int _errorCount = 0;

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorCount++);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLoginPressed() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Email y contraseña son obligatorios');
      return;
    }
    if (!isValidEmail(email)) {
      _showError('Email no válido');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().login(email, password);
      if (!mounted) return;
      // A '/' (AuthWrapper) y no a '/home': empujar HomeNavigation dejaría dos
      // instancias vivas, la del wrapper y la empujada encima.
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      _showError('Error al iniciar sesión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onForgotPasswordPressed() async {
    final sent = await showForgotPasswordDialog(
      context,
      initialEmail: _emailCtrl.text.trim(),
    );
    if (!sent || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Si el email tiene una cuenta, te enviamos un enlace para '
          'restablecer la contraseña.',
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return PressableScale(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textBlack,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _onLoginPressed,
          child: Text('Iniciar sesión', style: TextStyles.buttons),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          children: [
            const SizedBox(height: 60),

            FadeSlideIn(
              index: 0,
              child: Image.asset('assets/images/LogoInv_PingPro.png', height: 180),
            ),

            const SizedBox(height: 32),

            FadeSlideIn(
              index: 1,
              child: Center(
                child: Text(
                  'Iniciar sesión',
                  style: TextStyles.title,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 32),

            ShakeOnError(
              errorCount: _errorCount,
              child: Column(
                children: [
                  FadeSlideIn(
                    index: 2,
                    child: Column(
                      children: [
                        CustomTextField(hint: 'Email', controller: _emailCtrl),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hint: 'Contraseña',
                          obscure: true,
                          controller: _passwordCtrl,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeSlideIn(index: 3, child: _buildLoginButton()),
                ],
              ),
            ),

            const SizedBox(height: 90),

            FadeSlideIn(
              index: 4,
              child: TextButton(
                onPressed: _onForgotPasswordPressed,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: AppColors.secundary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            FadeSlideIn(
              index: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                  GestureDetector(
                    onTap:
                        () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/register'),
                    child: Text('Regístrate', style: TextStyles.loginRegister),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
