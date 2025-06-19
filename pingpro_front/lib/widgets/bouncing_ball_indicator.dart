import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class BouncingBallIndicator extends StatefulWidget {
  final double dotSize;
  final double ballSize;
  final Color dotColor;
  final Color ballColor;
  final Duration duration;

  const BouncingBallIndicator({
    super.key,
    this.dotSize = 12,
    this.ballSize = 16,
    this.dotColor = AppColors.secundary,
    this.ballColor = Colors.white,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<BouncingBallIndicator> createState() => _BouncingBallIndicatorState();
}

class _BouncingBallIndicatorState extends State<BouncingBallIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Parábola entre dos puntos
  Offset _parabola(double t, Offset start, Offset end, double height) {
    // t: 0..1
    double x = lerpDouble(start.dx, end.dx, t)!;
    double y = lerpDouble(start.dy, end.dy, t)! - 4 * height * t * (1 - t);
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 40,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Tres puntos en X
          final points = [Offset(10, 32), Offset(40, 32), Offset(70, 32)];

          // Animación: 0..0.5 rebota de 0 a 1, 0.5..1 rebota de 1 a 2
          double t = _animation.value;
          Offset ballPos;
          if (t < 0.5) {
            // Rebote de 0 a 1
            double localT = t / 0.5;
            ballPos = _parabola(localT, points[0], points[1], 18);
          } else {
            // Rebote de 1 a 2
            double localT = (t - 0.5) / 0.5;
            ballPos = _parabola(localT, points[1], points[2], 18);
          }

          return CustomPaint(
            painter: _BouncingBallPainter(points: points, ballPos: ballPos),
          );
        },
      ),
    );
  }
}

class _BouncingBallPainter extends CustomPainter {
  final List<Offset> points;
  final Offset ballPos;

  _BouncingBallPainter({required this.points, required this.ballPos});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint =
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.fill;

    // Dibuja los 3 puntos
    for (final p in points) {
      canvas.drawCircle(p, 6, dotPaint);
    }

    // Dibuja la pelota blanca (con sombra sutil)
    final ballPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(ballPos, 8, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _BouncingBallPainter oldDelegate) =>
      oldDelegate.ballPos != ballPos;
}
