import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/widgets/custom_text_field.dart';

class PingproLoginScreen extends StatefulWidget {
  const PingproLoginScreen({super.key});

  @override
  State<PingproLoginScreen> createState() => _PingproLoginScreenState();
}

class _PingproLoginScreenState extends State<PingproLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _onLoginPressed() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email y contraseña son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1) Firebase Auth + backend verify
      await AuthService().login(email: email, password: password);
      // 2) Navegar a Home
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/LogoInv_PingPro.png', height: 180),
              const SizedBox(height: 32),
              Text('Iniciar sesión', style: TextStyles.subTitle),
              const SizedBox(height: 32),
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
                        onPressed: _onLoginPressed,
                        child:
                            Text('Iniciar sesión', style: TextStyles.buttons),
                      ),
                    ),
              const SizedBox(height: 90),
              TextButton(
                onPressed: () {
                  // Ruta recuperación contraseña
                },
                child: Text('¿Olvidaste tu contraseña?',
                    style: TextStyle(color: AppColors.secundary)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta? ',
                      style: TextStyle(color: AppColors.textGray)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/register'),
                    child:
                        Text('Regístrate', style: TextStyles.loginRegister),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
