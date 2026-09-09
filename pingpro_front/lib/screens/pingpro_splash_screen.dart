/// Pantalla de carga entre el onboarding y el login.
///
/// Es puramente visual: espera 3 segundos fijos y navega, no aguarda a que
/// termine ninguna carga real (Firebase y dotenv ya se inicializan en main()).
///
/// PENDIENTE: el Timer no se cancela en dispose(). Si el usuario sale antes de
/// los 3 segundos, la navegación se dispara sobre un contexto ya desmontado.
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:pingpro_front/widgets/bouncing_ball_indicator.dart';

class PingproSplashScreen extends StatefulWidget {
  const PingproSplashScreen({super.key});

  @override
  State<PingproSplashScreen> createState() => _PingproSplashScreenState();
}

class _PingproSplashScreenState extends State<PingproSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simula carga, luego navega al login
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Imagen mitad arriba
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: double.infinity,
            child: Image.asset(
              'assets/images/loading_image.jpg',
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 24),

          // Logo con altura 180
          SizedBox(
            height: 180,
            child: Image.asset('assets/images/LogoInv_PingPro.png'),
          ),

          const SizedBox(height: 32),

          // Indicador animado con pelota rebotando
          const BouncingBallIndicator(),
        ],
      ),
    );
  }
}
