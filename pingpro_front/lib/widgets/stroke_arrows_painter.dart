// Pinta sobre la mesa del editor los puntos de destino y las flechas.
//
// Los destinos son aros pequeños en el campo del rival; el que se va a usar
// mientras se arrastra se rellena, para ver dónde caerá la flecha antes de
// soltarla. Cada flecha va de un punto de golpeo a su destino, con su número
// de orden en la punta. La que se está arrastrando se pinta más tenue, y en
// gris mientras esté sobre tu propio campo, donde soltarla no crearía golpe.
//
// Recibe las posiciones en coordenadas de mesa y el rectángulo de la mesa en
// el lienzo, así que todo sigue en su sitio si cambia el tamaño.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/table_geometry.dart';

/// Una flecha: índice en strokeOrigins del que sale y dónde termina
/// (coordenadas de mesa).
typedef StrokeArrow = ({int originIndex, Offset end});

class StrokeArrowsPainter extends CustomPainter {
  final Rect table;
  final List<StrokeArrow> arrows;
  final StrokeArrow? dragging;

  /// Destino al que se engancharía la flecha arrastrada, si la hay.
  final StrokeTarget? snapped;

  const StrokeArrowsPainter({
    required this.table,
    required this.arrows,
    this.dragging,
    this.snapped,
  });

  static const _headLength = 12.0;
  static const _badgeRadius = 10.0;
  static const _targetRadius = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTargets(canvas);

    for (var i = 0; i < arrows.length; i++) {
      _drawArrow(canvas, arrows[i], AppColors.primary);
      _drawBadge(canvas, toCanvas(arrows[i].end, table), i + 1);
    }

    final live = dragging;
    if (live == null) return;
    final target = snapped;
    if (target == null) {
      _drawArrow(canvas, live, AppColors.textGray);
      return;
    }
    final snappedArrow = (originIndex: live.originIndex, end: target.position);
    _drawArrow(canvas, snappedArrow, AppColors.primary.withValues(alpha: 0.6));
  }

  void _drawTargets(Canvas canvas) {
    final ring = Paint()
      ..color = AppColors.textGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = AppColors.primary;

    for (final target in strokeTargets) {
      final center = toCanvas(target.position, table);
      canvas.drawCircle(center, _targetRadius, target == snapped ? fill : ring);
    }
  }

  void _drawArrow(Canvas canvas, StrokeArrow arrow, Color color) {
    final start = toCanvas(strokeOrigins[arrow.originIndex].position, table);
    final end = toCanvas(arrow.end, table);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    // Punta: dos trazos a ±25° de la dirección de la flecha.
    final angle = (end - start).direction;
    canvas.drawLine(end, end - Offset.fromDirection(angle - 0.45, _headLength), paint);
    canvas.drawLine(end, end - Offset.fromDirection(angle + 0.45, _headLength), paint);
  }

  void _drawBadge(Canvas canvas, Offset at, int number) {
    canvas.drawCircle(at, _badgeRadius, Paint()..color = AppColors.primary);

    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(color: AppColors.textBlack, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(StrokeArrowsPainter old) =>
      old.table != table || old.arrows != arrows || old.dragging != dragging || old.snapped != snapped;
}
