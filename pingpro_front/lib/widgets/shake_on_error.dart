// Sacude a su hijo en horizontal cada vez que sube [errorCount].
//
// Un contador en vez de una GlobalKey: la pantalla solo suma uno cuando algo
// falla y no necesita conocer el State de este widget.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/shake_offset.dart';

class ShakeOnError extends StatefulWidget {
  final int errorCount;
  final Widget child;

  const ShakeOnError({super.key, required this.errorCount, required this.child});

  @override
  State<ShakeOnError> createState() => _ShakeOnErrorState();
}

class _ShakeOnErrorState extends State<ShakeOnError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(ShakeOnError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorCount <= oldWidget.errorCount) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(shakeOffset(_controller.value), 0),
        child: child,
      ),
    );
  }
}
