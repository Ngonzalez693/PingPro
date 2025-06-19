import 'package:flutter/material.dart';
import 'package:pingpro_front/screens/pingpro_login_screen.dart';
import 'package:pingpro_front/screens/pingpro_register_screen.dart';
import 'package:pingpro_front/screens/pingpro_splash_screen.dart';
import 'package:pingpro_front/screens/pingpro_welcome_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const PingproWelcomeScreen(),
        '/login': (context) => const PingproLoginScreen(),
        '/register': (context) => const PingproRegisterScreen(),
        '/splash': (context) => const PingproSplashScreen(),
      },
    );
  }
}
