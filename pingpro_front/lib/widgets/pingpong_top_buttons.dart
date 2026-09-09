// Fila de 5 botones "+" en el lado lejano de la mesa (destino de la pelota).
//
// Las posiciones son píxeles absolutos ajustados al tamaño fijo de
// PingPongTable; ver la limitación explicada allí.
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/plus_button.dart';

class PingPongTopButtons extends StatelessWidget {
  final double startTop;
  final double startLeft;
  final int count;

  const PingPongTopButtons({
    super.key,
    this.startTop = 250,
    this.startLeft = -1,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(count, (index) {
        return Positioned(
          top: startTop + (index * 0.1),
          left: startLeft + (index * 62.6),
          child: const PlusButton(),
        );
      }),
    );
  }
}
