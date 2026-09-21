import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/chart_axis.dart';

void main() {
  group('ChartAxis.forValues', () {
    test('deja aire sobre el valor más alto', () {
      // El caso de la captura: un pico de 4 que llegaba justo al borde y se
      // cortaba el trazo por la mitad.
      final axis = ChartAxis.forValues([0, 0, 1, 4, 1, 0, 0]);

      expect(axis.max, greaterThan(4));
      expect(axis.max, 5);
      expect(axis.interval, 1);
    });

    test('una serie vacía sigue dando un eje dibujable', () {
      final axis = ChartAxis.forValues([]);

      expect(axis.max, 1);
      expect(axis.interval, 1);
    });

    test('todo a cero no deja el eje sin rango', () {
      final axis = ChartAxis.forValues([0, 0, 0]);

      expect(axis.max, 1);
      expect(axis.interval, 1);
    });

    test('con valores altos agranda el paso en vez de amontonar etiquetas', () {
      final axis = ChartAxis.forValues([2, 10, 5]);

      expect(axis.interval, 3);
      expect(axis.max, 12);
    });

    test('el tope siempre es múltiplo del intervalo', () {
      for (final peak in [1, 3, 4, 7, 8, 9, 20, 57]) {
        final axis = ChartAxis.forValues([peak]);

        expect(axis.max % axis.interval, 0, reason: 'pico $peak');
        expect(axis.max, greaterThan(peak), reason: 'pico $peak');
      }
    });

    test('las etiquetas son enteras', () {
      final axis = ChartAxis.forValues([2, 10, 5]);

      expect(axis.label(0), '0');
      expect(axis.label(3), '3');
      expect(axis.label(12), '12');
    });
  });
}
