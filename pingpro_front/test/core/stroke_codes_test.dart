import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

SequenceStep _step({
  int hit = 1,
  int rotation = 2,
  int zone = 3,
  int direction = 6,
  int side = 1,
  int ownZone = ZoneCode.free,
}) =>
    SequenceStep(hit: hit, rotation: rotation, zone: zone, direction: direction, side: side, ownZone: ownZone);

void main() {
  group('describeStep', () {
    test('junta los códigos en una línea legible', () {
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

    test('con profundidad propia dice desde dónde golpea', () {
      expect(
        describeStep(_step(ownZone: ZoneCode.long)),
        'Forehand Topspin desde Largo, Largo a Esquina Izquierda',
      );
      expect(describeStep(_step(ownZone: ZoneCode.short)), contains('desde Corto,'));
    });

    test('sin profundidad propia se lee como antes', () {
      expect(describeStep(_step()), 'Forehand Topspin Largo a Esquina Izquierda');
    });

    test('los golpes nuevos tienen nombre', () {
      expect(describeStep(_step(hit: HitCode.hook, rotation: 1)), startsWith('Hook Back Spin'));
      expect(describeStep(_step(hit: HitCode.globo)), startsWith('Globo'));
      expect(describeStep(_step(hit: HitCode.smash)), startsWith('Smash'));
    });
  });

  group('tablas de nombres', () {
    // Los rangos son los CHECK de la tabla exercise_steps del backend.
    test('cubren todos los valores que admite la base', () {
      expect(hitLabels.keys, List.generate(12, (i) => i + 1));
      expect(rotationLabels.keys, List.generate(7, (i) => i + 1));
      expect(zoneLabels.keys, List.generate(4, (i) => i + 1));
      expect(directionLabels.keys, List.generate(8, (i) => i + 1));
      expect(sideLabels.keys, List.generate(5, (i) => i + 1));
    });
  });

  group('tableSideOf', () {
    test('agrupa los cinco lados en derecha, centro e izquierda', () {
      expect([1, 2, 3, 4, 5].map(tableSideOf), [
        TableSide.right,
        TableSide.right,
        TableSide.center,
        TableSide.left,
        TableSide.left,
      ]);
    });
  });

  group('isPivot', () {
    test('es un forehand desde el lado izquierdo', () {
      expect(isPivot(_step(hit: HitCode.forehand, side: 4)), isTrue);
      expect(isPivot(_step(hit: HitCode.forehand, side: 5)), isTrue);
    });

    test('no lo es desde el centro ni con otro golpe', () {
      expect(isPivot(_step(hit: HitCode.forehand, side: 3)), isFalse);
      expect(isPivot(_step(hit: HitCode.backhand, side: 5)), isFalse);
      expect(isPivot(_step(hit: HitCode.forehandOrBackhand, side: 5)), isFalse);
    });
  });

  group('allowedRotations', () {
    test('Hook, Globo y Smash solo admiten sus rotaciones', () {
      expect(allowedRotations(HitCode.hook), [1]);
      expect(allowedRotations(HitCode.globo), [2, 3, 4, 5]);
      expect(allowedRotations(HitCode.smash), [2, 5]);
    });

    test('el resto de golpes admite todas', () {
      expect(allowedRotations(HitCode.forehand), rotationLabels.keys.toList());
      expect(allowedRotations(HitCode.serve), rotationLabels.keys.toList());
    });
  });

  group('hitsAvailableFrom', () {
    test('desde el fondo están todos los golpes', () {
      expect(hitsAvailableFrom(ZoneCode.long), hitLabels.keys.toList());
    });

    test('desde otra profundidad no hay Globo ni Smash, pero sí Hook', () {
      for (final ownZone in [ZoneCode.short, ZoneCode.middle, ZoneCode.free]) {
        final hits = hitsAvailableFrom(ownZone);

        expect(hits, isNot(contains(HitCode.globo)));
        expect(hits, isNot(contains(HitCode.smash)));
        expect(hits, contains(HitCode.hook));
      }
    });
  });
}
