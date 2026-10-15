// Splash del arranque con sesión abierta: lanza la carga de datos y avisa con
// `onReady` cuando terminó, acotado por waitForStartup (core/startup_wait.dart).
//
// No navega: quien lo muestra (AuthWrapper) decide qué viene después, así el
// portero de sesión sigue siendo el único que elige entre Welcome y Home.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pingpro_front/core/startup_wait.dart';
import 'package:pingpro_front/widgets/splash_view.dart';

class StartupSplash extends StatefulWidget {
  /// Carga que se espera antes de avisar; se llama una sola vez.
  final Future<void> Function() load;
  final VoidCallback onReady;

  const StartupSplash({super.key, required this.load, required this.onReady});

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  @override
  void initState() {
    super.initState();
    // whenComplete y no then: si la carga fallara, el splash tiene que dar
    // paso igual. El error sigue su curso como no capturado y queda en el log.
    unawaited(waitForStartup(widget.load()).whenComplete(() {
      if (mounted) widget.onReady();
    }));
  }

  @override
  Widget build(BuildContext context) => const SplashView();
}
