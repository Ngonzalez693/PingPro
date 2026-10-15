// La cara del splash: logo, título de marca y la pelota rebotando. Sin lógica
// de navegación, para que la compartan el splash entre el onboarding y el
// login (PingproSplashScreen) y el del arranque con sesión (StartupSplash).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/bouncing_ball_indicator.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

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
