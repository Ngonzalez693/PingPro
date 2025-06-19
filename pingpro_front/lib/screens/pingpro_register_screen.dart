import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/custom_text_field.dart';

class PingproRegisterScreen extends StatelessWidget {
  const PingproRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              SizedBox(height: 60),
              Image.asset(
                'assets/images/LogoInv_PingPro.png',
                height: 180,
              ),
              SizedBox(height: 32),
              Text(
                'Crear cuenta',
                style: TextStyles.subTitle,
              ),
              SizedBox(height: 32),
              CustomTextField(hint: 'Nombre de Usuario'),
              SizedBox(height: 16),
              CustomTextField(hint: 'Email'),
              SizedBox(height: 16),
              CustomTextField(hint: 'Contraseña', obscure: true),
              SizedBox(height: 24),
              SizedBox(
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
                  onPressed: () {},
                  child: Text(
                    'Crear cuenta',
                    style: TextStyles.buttons,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ya tienes cuenta? ',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Iniciar sesión',
                      style: TextStyles.loginRegister,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
