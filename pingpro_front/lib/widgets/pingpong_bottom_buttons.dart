import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/plus_button.dart';

class PingPongBottomButtons extends StatelessWidget {
  final double startBottom;
  final double startLeft;
  final int count;

  const PingPongBottomButtons({
    super.key,
    this.startBottom = 0,
    this.startLeft = -1,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(count, (index) {
        return Positioned(
          bottom: startBottom + (index * 0.1),
          left: startLeft + (index * 62.6),
          child: const PlusButton(),
        );
      }),
    );
  }
}
