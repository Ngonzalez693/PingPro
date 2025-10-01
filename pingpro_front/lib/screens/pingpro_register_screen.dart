import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/widgets/custom_text_field.dart';

class PingproRegisterScreen extends StatefulWidget {
  const PingproRegisterScreen({super.key});

  @override
  State<PingproRegisterScreen> createState() => _PingproRegisterScreenState();
}

class _PingproRegisterScreenState extends State<PingproRegisterScreen> {
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _onRegisterPressed() async {
    final displayName = _displayNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (displayName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
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
            Image.asset('assets/images/LogoInv_PingPro.png', height: 180),
            const SizedBox(height: 32),
            Text('Crear cuenta', style: TextStyles.subTitle),
            const SizedBox(height: 32),
            CustomTextField(
              hint: 'Nombre de Usuario',
              controller: _displayNameCtrl,
            ),
            const SizedBox(height: 16),
            CustomTextField(hint: 'Email', controller: _emailCtrl),
            const SizedBox(height: 16),
            CustomTextField(
              hint: 'Contraseña',
              obscure: true,
              controller: _passwordCtrl,
            ),

            const SizedBox(height: 24),

            _isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : SizedBox(
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
                      onPressed: _onRegisterPressed,
                      child: Text('Crear cuenta', style: TextStyles.buttons),
                    ),
                  ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ya tienes cuenta? ',
                  style: TextStyle(color: AppColors.textGray),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text('Iniciar sesión', style: TextStyles.loginRegister),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
