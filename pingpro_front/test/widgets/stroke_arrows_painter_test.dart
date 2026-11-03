import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/widgets/stroke_arrows_painter.dart';

const _table = Rect.fromLTWH(0, 0, 200, 300);
const _arrows = <StrokeArrow>[(originIndex: 0, end: Offset(0.5, 0.2))];

StrokeArrowsPainter _painter(PingProColors colors) =>
    StrokeArrowsPainter(table: _table, arrows: _arrows, colors: colors);

void main() {
  // Al cambiar de tema con el editor abierto, las flechas tienen que tomar
  // los colores nuevos sin esperar a que se mueva algo.
  test('repinta si cambia la paleta', () {
    final other = PingProColors.dark.copyWith(brand: const Color(0xFF5C6300));

    expect(_painter(other).shouldRepaint(_painter(PingProColors.dark)), isTrue);
  });

  test('con la misma paleta y las mismas flechas no repinta', () {
    expect(_painter(PingProColors.dark).shouldRepaint(_painter(PingProColors.dark)), isFalse);
  });
}
