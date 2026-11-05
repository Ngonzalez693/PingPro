// Fuerza el tema oscuro en lo que envuelve, aunque la app esté en claro.
//
// Lo usan bienvenida, login, registro y los splash: sus imágenes y el logo
// están dibujados sobre negro, y la pantalla de arranque de Android también es
// negra. Los diálogos que se abren desde dentro heredan este tema, pero no las
// pantallas que se empujan con el Navigator: esas van en las rutas de main.dart,
// envueltas aquí, y se abren por nombre.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

class AlwaysDark extends StatelessWidget {
  final Widget child;

  const AlwaysDark({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAppTheme(PingProColors.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyleFor(PingProColors.dark),
        child: child,
      ),
    );
  }
}
