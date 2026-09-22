import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

/// Siempre elige la primera opción: hace deterministas los sorteos.
class _FirstOption implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

SequenceStep _step({
  int hit = HitCode.forehand,
  int rotation = 2,
  int side = 1,
  int ownZone = ZoneCode.free,
}) =>
    SequenceStep(hit: hit, rotation: rotation, zone: 3, direction: 4, side: side, ownZone: ownZone);

List<String> _clips(List<SequenceStep> steps) =>
    clipsForSequence(steps, random: _FirstOption());

/// Clip del golpe de un ejercicio de un solo paso (el primero es PosInicial).
String _strokeOf(SequenceStep step) => _clips([step]).last;

// Un golpe por posición. El backhand desde la izquierda no es pivot.
final _right = _step(side: 1);
final _center = _step(side: 3);
final _left = _step(hit: HitCode.backhand, side: 5);
final _pivot = _step(side: 5);

/// Clip de desplazamiento entre dos golpes, o null si no hay.
String? _movement(SequenceStep from, SequenceStep to) {
  final clips = _clips([from, to]); // [PosInicial, from, (mov), to]
  return clips.length == 4 ? clips[2] : null;
}

// Los 29 clips de PingProAnimations.glb, copiados del archivo subido.
const _clipsInFile = {
  'PosInicial', 'Boomerang', 'CorteAtras', 'CorteDer', 'CorteReves',
  'DesIzqDer', 'Flip', 'Globo', 'Hook', 'InicioReves', 'LoopDerecha',
  'LoopPivot', 'MovCortoApivot', 'MovCortoDerIzq', 'MovCortoIzqDer',
  'MovLargoCruce', 'MovLargoDerIzq', 'MovLargoIzqDer', 'MovLargoPivotDer',
  'Ning', 'NingDer', 'Reves', 'SaqueInv', 'SaquePendulo', 'SaqueReves',
  'Smash', 'TopspinForehand', 'TopspinPivot', 'Topspin_Backhand_000',
};

void main() {
  group('forehand', () {
    test('topspin desde la derecha o el centro', () {
      expect(_strokeOf(_step(side: 1)), 'TopspinForehand');
      expect(_strokeOf(_step(side: 3)), 'TopspinForehand');
    });

    test('topspin desde la izquierda es pivot', () {
      expect(_strokeOf(_step(side: 4)), 'TopspinPivot');
      expect(_strokeOf(_step(side: 5)), 'TopspinPivot');
    });

    test('liftado', () {
      expect(_strokeOf(_step(rotation: 6, side: 2)), 'LoopDerecha');
      expect(_strokeOf(_step(rotation: 6, side: 5)), 'LoopPivot');
    });

    test('back spin en cualquier lado', () {
      expect(_strokeOf(_step(rotation: 1, side: 1)), 'CorteDer');
      expect(_strokeOf(_step(rotation: 1, side: 5)), 'CorteDer');
    });

    test('drive, efectos laterales y libre se animan como topspin', () {
      for (final rotation in [3, 4, 5, 7]) {
        expect(_strokeOf(_step(rotation: rotation, side: 1)), 'TopspinForehand');
        expect(_strokeOf(_step(rotation: rotation, side: 4)), 'TopspinPivot');
      }
    });
  });

  group('backhand', () {
    SequenceStep backhand(int rotation) =>
        _step(hit: HitCode.backhand, rotation: rotation, side: 5);

    test('una animación por rotación', () {
      expect(_strokeOf(backhand(2)), 'Topspin_Backhand_000');
      expect(_strokeOf(backhand(6)), 'InicioReves');
      expect(_strokeOf(backhand(1)), 'CorteReves');
      expect(_strokeOf(backhand(5)), 'Reves');
    });

    test('efectos laterales y libre se animan como topspin', () {
      for (final rotation in [3, 4, 7]) {
        expect(_strokeOf(backhand(rotation)), 'Topspin_Backhand_000');
      }
    });

    test('back spin desde el fondo es el corte defensivo', () {
      expect(
        _strokeOf(_step(hit: HitCode.backhand, rotation: 1, side: 5, ownZone: ZoneCode.long)),
        'CorteAtras',
      );
    });

    test('back spin desde otra profundidad es el corte normal', () {
      for (final ownZone in [ZoneCode.short, ZoneCode.middle, ZoneCode.free]) {
        expect(
          _strokeOf(_step(hit: HitCode.backhand, rotation: 1, side: 5, ownZone: ownZone)),
          'CorteReves',
        );
      }
    });
  });

  group('forehand o backhand', () {
    test('desde la izquierda usa las reglas de backhand', () {
      expect(_strokeOf(_step(hit: HitCode.forehandOrBackhand, rotation: 1, side: 5)), 'CorteReves');
    });

    test('desde la derecha o el centro usa las de forehand', () {
      expect(_strokeOf(_step(hit: HitCode.forehandOrBackhand, rotation: 1, side: 1)), 'CorteDer');
      expect(_strokeOf(_step(hit: HitCode.forehandOrBackhand, rotation: 6, side: 3)), 'LoopDerecha');
    });

    test('desde la izquierda y el fondo, con back spin, es el corte defensivo', () {
      final step = _step(hit: HitCode.forehandOrBackhand, rotation: 1, side: 5, ownZone: ZoneCode.long);

      expect(_strokeOf(step), 'CorteAtras');
    });
  });

  group('flicks', () {
    test('forehand flick', () {
      expect(_strokeOf(_step(hit: HitCode.forehandFlick, side: 5)), 'Flip');
    });

    test('banana flick depende del lado', () {
      expect(_strokeOf(_step(hit: HitCode.bananaFlick, side: 1)), 'NingDer');
      expect(_strokeOf(_step(hit: HitCode.bananaFlick, side: 2)), 'NingDer');
      expect(_strokeOf(_step(hit: HitCode.bananaFlick, side: 3)), 'Ning');
      expect(_strokeOf(_step(hit: HitCode.bananaFlick, side: 5)), 'Ning');
    });

    test('strawberry flick', () {
      expect(_strokeOf(_step(hit: HitCode.strawberryFlick)), 'Boomerang');
    });
  });

  group('golpes nuevos', () {
    test('cada uno tiene su clip', () {
      expect(_strokeOf(_step(hit: HitCode.hook, rotation: 1, side: 5)), 'Hook');
      expect(_strokeOf(_step(hit: HitCode.globo, side: 5, ownZone: ZoneCode.long)), 'Globo');
      expect(_strokeOf(_step(hit: HitCode.smash, side: 1, ownZone: ZoneCode.long)), 'Smash');
    });

    test('un smash desde la izquierda no es pivot', () {
      final steps = [_step(side: 1), _step(hit: HitCode.smash, side: 5, ownZone: ZoneCode.long)];

      expect(_clips(steps), ['PosInicial', 'TopspinForehand', 'MovLargoDerIzq', 'Smash']);
    });
  });

  group('servicio', () {
    test('no va precedido de la posición inicial', () {
      expect(_clips([_step(hit: HitCode.serve)]), ['SaquePendulo']);
    });

    test('sortea entre los tres saques', () {
      final seen = {
        for (var seed = 0; seed < 50; seed++)
          ...clipsForSequence([_step(hit: HitCode.serve)], random: Random(seed)),
      };
      expect(seen, {'SaquePendulo', 'SaqueInv', 'SaqueReves'});
    });
  });

  test('un código que la app no conoce se anima con la posición inicial', () {
    expect(_strokeOf(_step(hit: 99)), 'PosInicial');
  });

  group('desplazamientos', () {
    test('ninguno si el golpe siguiente es desde la misma posición', () {
      expect(_movement(_right, _step(side: 2)), isNull);
      expect(_movement(_left, _left), isNull);
    });

    test('cortos entre zonas vecinas', () {
      expect(_movement(_right, _center), 'MovCortoDerIzq');
      expect(_movement(_center, _left), 'MovCortoDerIzq');
      expect(_movement(_left, _center), 'MovCortoIzqDer');
      expect(_movement(_center, _right), 'MovCortoIzqDer');
    });

    test('largos de una esquina a la otra', () {
      expect(_movement(_right, _left), 'MovLargoDerIzq');
      expect(_movement(_left, _right), 'MovLargoIzqDer');
    });

    test('hacia el pivot desde cualquier sitio', () {
      expect(_movement(_right, _pivot), 'MovCortoApivot');
      expect(_movement(_center, _pivot), 'MovCortoApivot');
      expect(_movement(_left, _pivot), 'MovCortoApivot');
    });

    test('del pivot a la derecha o al centro', () {
      expect(_movement(_pivot, _right), 'MovLargoPivotDer');
      expect(_movement(_pivot, _center), 'MovLargoPivotDer');
    });

    test('la salida del pivot sortea entre dos clips', () {
      final seen = {
        for (var seed = 0; seed < 50; seed++)
          clipsForSequence([_pivot, _right], random: Random(seed))[2],
      };
      expect(seen, {'MovLargoPivotDer', 'MovLargoCruce'});
    });

    test('del pivot a la izquierda cambia a revés sin moverse', () {
      expect(_movement(_pivot, _left), isNull);
    });
  });

  group('secuencia', () {
    test('vacía queda en la posición inicial', () {
      expect(_clips([]), ['PosInicial']);
    });

    test('Libre termina el ejercicio en la posición inicial', () {
      final steps = [_right, _step(hit: HitCode.free), _left];
      expect(_clips(steps), ['PosInicial', 'TopspinForehand', 'PosInicial']);
    });

    test('Libre como primer paso no repite la posición inicial', () {
      expect(_clips([_step(hit: HitCode.free)]), ['PosInicial']);
    });

    test('Hasta que se caiga no anima nada ni corta el desplazamiento', () {
      final steps = [_right, _step(hit: HitCode.untilItFalls), _left];
      expect(_clips(steps), [
        'PosInicial',
        'TopspinForehand',
        'MovLargoDerIzq',
        'Topspin_Backhand_000',
      ]);
    });

    test('solo pide clips que existen en el archivo', () {
      final all = [
        for (var hit = 1; hit <= 12; hit++)
          for (var rotation = 1; rotation <= 7; rotation++)
            for (var side = 1; side <= 5; side++)
              for (var ownZone = 1; ownZone <= 4; ownZone++)
                _step(hit: hit, rotation: rotation, side: side, ownZone: ownZone),
      ];
      final withoutFree = all.where((s) => s.hit != HitCode.free).toList();
      final used = {
        for (final step in all) ..._clips([step]),
        for (var seed = 0; seed < 20; seed++)
          ...clipsForSequence(withoutFree, random: Random(seed)),
      };
      expect(used.difference(_clipsInFile), isEmpty);
    });
  });
}
