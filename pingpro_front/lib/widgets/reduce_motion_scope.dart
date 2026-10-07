// Suma "Reducir animaciones" al ajuste del sistema en MediaQuery.
//
// Las animaciones propias de la app leen MediaQuery.disableAnimations, así que
// basta con reescribirlo aquí, encima del Navigator: respetan las dos fuentes
// sin saber de dónde viene, y en vivo, porque escucha a AppPreferences.
// Las transiciones de rutas, diálogos y hojas inferiores del framework no lo
// leen: el interruptor de la app no las cubre, solo el ajuste del sistema.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';

class ReduceMotionScope extends StatelessWidget {
  final AppPreferences preferences;
  final Widget child;

  const ReduceMotionScope({super.key, required this.preferences, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      child: child,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || preferences.reduceMotion,
          ),
          child: child!,
        );
      },
    );
  }
}
