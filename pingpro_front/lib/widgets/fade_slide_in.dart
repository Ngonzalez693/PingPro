// Aparición con fundido y un pequeño desplazamiento hacia arriba.
//
// Para escalonar varios bloques se le pasa a cada uno su `index`: el retraso
// va dentro de la curva (Interval) y no en un Timer, así no queda nada
// pendiente si la pantalla se cierra antes de terminar.
import 'package:flutter/material.dart';

class FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;

  static const _step = Duration(milliseconds: 80);
  static const _itemDuration = Duration(milliseconds: 400);
  static const _offsetY = 16.0;

  const FadeSlideIn({super.key, required this.index, required this.child});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = FadeSlideIn._step * widget.index;
    final total = delay + FadeSlideIn._itemDuration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    // Con "reducir animaciones" activado, el contenido aparece directo.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * FadeSlideIn._offsetY),
            child: child,
          ),
        );
      },
    );
  }
}
