// Pantalla de carga entre el onboarding y el login.
//
// Es puramente visual: espera 3 segundos fijos y navega, no aguarda a que
// termine ninguna carga real (Firebase y dotenv ya se inicializan en main()).
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/bouncing_ball_indicator.dart';

class PingproSplashScreen extends StatefulWidget {
  const PingproSplashScreen({super.key});

  @override
  State<PingproSplashScreen> createState() => _PingproSplashScreenState();
}

class _PingproSplashScreenState extends State<PingproSplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  // Si el usuario sale antes de los 3 segundos, la navegación no debe
  // dispararse sobre un contexto ya desmontado.
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/LogoInv_PingPro.png', height: 180),
            const SizedBox(height: 16),
            Text(
              'PingPro',
              style: TextStyles.brandTitle.copyWith(fontSize: 40),
            ),
            const SizedBox(height: 32),
            const BouncingBallIndicator(),
          ],
        ),
      ),
    );
  }
}
