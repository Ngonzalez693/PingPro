// Entrada escalonada para los elementos de una lista.
//
// Solo anima las primeras posiciones, que son las visibles al llegar los
// datos: más abajo el retraso acumulado (80 ms por posición) haría esperar a
// quien hace scroll, así que esos elementos aparecen sin animación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/fade_slide_in.dart';

class StaggeredEntrance extends StatelessWidget {
  static const _animatedCount = 6;

  final int index;
  final Widget child;

  const StaggeredEntrance({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (index >= _animatedCount) return child;
    return FadeSlideIn(index: index, child: child);
  }
}
