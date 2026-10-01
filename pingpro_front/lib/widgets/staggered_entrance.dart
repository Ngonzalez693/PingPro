// Entrada escalonada para los elementos de una lista.
//
// Solo anima las primeras posiciones, que son las visibles al llegar los
// datos: más abajo el retraso acumulado (80 ms por posición) haría esperar a
// quien hace scroll, así que esos elementos aparecen sin animación.
//
// `startIndex` sirve cuando la lista va debajo de otros bloques que ya se
// escalonan: la primera tarjeta continúa la secuencia en vez de entrar a la
// vez que el encabezado.
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/fade_slide_in.dart';

class StaggeredEntrance extends StatelessWidget {
  static const _animatedCount = 6;

  final int index;
  final int startIndex;
  final Widget child;

  const StaggeredEntrance({
    super.key,
    required this.index,
    this.startIndex = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= _animatedCount) return child;
    return FadeSlideIn(index: startIndex + index, child: child);
  }
}
