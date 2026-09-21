// Mesa de tenis de mesa vista desde arriba: bordes, red y línea central.
//
// Solo dibuja. Ocupa el espacio que le den con las proporciones de una mesa
// reglamentaria, y todo se pinta en fracciones de ese tamaño, así que se ve
// igual en cualquier pantalla. Los puntos de golpeo y las flechas los pone el
// editor de secuencias encima, usando core/table_geometry.dart.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/table_geometry.dart';

class PingPongTable extends StatelessWidget {
  const PingPongTable({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: tableAspectRatio,
      child: CustomPaint(painter: _TablePainter()),
    );
  }
}

class _TablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.textGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      line,
    );
    // Línea central: separa los lados derecho e izquierdo de cada campo.
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), line);

    // La red, más marcada: es la frontera entre tu campo y el del rival.
    final net = Paint()
      ..color = AppColors.textWhite
      ..strokeWidth = 3;
    final netDy = size.height * netY;
    canvas.drawLine(Offset(0, netDy), Offset(size.width, netDy), net);
  }

  @override
  bool shouldRepaint(_TablePainter oldDelegate) => false;
}
