import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/shake_offset.dart';

void main() {
  group('shakeOffset', () {
    test('empieza y termina en reposo', () {
      expect(shakeOffset(0), closeTo(0, 1e-9));
      expect(shakeOffset(1), closeTo(0, 1e-9));
    });

    test('nunca se aparta más que la amplitud', () {
      for (var i = 0; i <= 100; i++) {
        expect(shakeOffset(i / 100).abs(), lessThanOrEqualTo(shakeAmplitude));
      }
    });

    test('va a los dos lados, como un "no"', () {
      final values = [for (var i = 0; i <= 100; i++) shakeOffset(i / 100)];
      expect(values.any((v) => v > 1), isTrue);
      expect(values.any((v) => v < -1), isTrue);
    });

    test('se va apagando: la segunda mitad se mueve menos que la primera', () {
      double peak(Iterable<int> range) =>
          range.map((i) => shakeOffset(i / 100).abs()).reduce((a, b) => a > b ? a : b);
      expect(peak(Iterable.generate(50, (i) => 50 + i)), lessThan(peak(Iterable.generate(50))));
    });
  });
}
