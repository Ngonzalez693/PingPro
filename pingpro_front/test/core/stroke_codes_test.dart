import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

SequenceStep _step({int hit = 1, int rotation = 2, int zone = 3, int direction = 6, int side = 1}) =>
    SequenceStep(hit: hit, rotation: rotation, zone: zone, direction: direction, side: side);

void main() {
  group('describeStep', () {
    test('junta los cinco códigos en una línea legible', () {
      expect(describeStep(_step()), 'Forehand Topspin Largo a Esquina Izquierda');
    });

    test('un forehand desde la zona de pivot se llama Forehand Pivot', () {
      expect(describeStep(_step(side: 4)), startsWith('Forehand Pivot'));
      expect(describeStep(_step(side: 5)), startsWith('Forehand Pivot'));
    });

    test('un backhand desde la misma zona conserva su nombre', () {
      expect(describeStep(_step(hit: 2, side: 5)), startsWith('Backhand '));
    });

    test('un código que la app no conoce no rompe la descripción', () {
      expect(describeStep(_step(hit: 99)), startsWith('Desconocido'));
    });
  });

  group('tablas de nombres', () {
    // Los rangos son los CHECK de la tabla exercise_steps del backend.
    test('cubren todos los valores que admite la base', () {
      expect(hitLabels.keys, List.generate(9, (i) => i + 1));
      expect(rotationLabels.keys, List.generate(7, (i) => i + 1));
      expect(zoneLabels.keys, List.generate(4, (i) => i + 1));
      expect(directionLabels.keys, List.generate(8, (i) => i + 1));
      expect(sideLabels.keys, List.generate(5, (i) => i + 1));
    });
  });
}
