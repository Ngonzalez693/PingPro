import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/chart_reveal.dart';

void main() {
  group('revealStops', () {
    test('al empezar no hay tramo visible', () {
      expect(revealStops(0), [0, 0, 0, 1]);
    });

    test('a mitad corta la línea en el centro', () {
      expect(revealStops(0.5), [0, 0.5, 0.5, 1]);
    });

    test('al terminar la línea es visible entera', () {
      expect(revealStops(1), [0, 1, 1, 1]);
    });

    test('un progreso fuera de 0..1 se recorta', () {
      expect(revealStops(-0.2), [0, 0, 0, 1]);
      expect(revealStops(1.3), [0, 1, 1, 1]);
    });
  });

  group('isRevealed', () {
    test('un punto aparece cuando la línea lo alcanza', () {
      expect(isRevealed(x: 3, maxX: 6, progress: 0.4), isFalse);
      expect(isRevealed(x: 3, maxX: 6, progress: 0.5), isTrue);
    });

    test('el primer punto se ve desde el principio', () {
      expect(isRevealed(x: 0, maxX: 6, progress: 0), isTrue);
    });

    test('al terminar se ven todos', () {
      for (var x = 0; x <= 6; x++) {
        expect(isRevealed(x: x.toDouble(), maxX: 6, progress: 1), isTrue);
      }
    });
  });
}
