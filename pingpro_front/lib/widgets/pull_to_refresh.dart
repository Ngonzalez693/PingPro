// "Tirar para recargar": desde arriba de una lista, tirar hacia abajo vuelve a
// pedir los datos al servidor.
//
// Todas las pantallas pasan por aquí en vez de usar RefreshIndicator
// directamente, para que cambiar el indicador (está previsto uno propio, con
// la raqueta y la pelota) toque solo este archivo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class PullToRefresh extends StatelessWidget {
  /// Para el scroll de `child`: con poco contenido la lista no tiene scroll
  /// propio y, sin esto, el gesto de tirar no llegaría al indicador.
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics();

  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.tab,
      child: child,
    );
  }
}
