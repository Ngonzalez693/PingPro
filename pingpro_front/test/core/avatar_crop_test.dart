import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/avatar_crop.dart';

void main() {
  // Con la escala mínima la foto cubre el círculo entero: nunca quedan
  // esquinas vacías, sea apaisada o vertical.
  test('una foto apaisada cubre el círculo por su alto', () {
    expect(coverScale(const Size(1000, 500), 300), 0.6);
  });

  test('una foto vertical cubre el círculo por su ancho', () {
    expect(coverScale(const Size(400, 1600), 300), 0.75);
  });
}
