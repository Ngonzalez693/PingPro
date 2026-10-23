import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/viewer/chain_plan.dart';
import 'package:pingpro_front/core/viewer/viewer_bridge.dart';

void main() {
  group('parseViewerEvent', () {
    test('ready', () {
      expect(parseViewerEvent('{"type":"ready"}'), isA<ViewerReady>());
    });

    test('playing con su índice', () {
      final event = parseViewerEvent('{"type":"playing","index":3}');

      expect(event, isA<ViewerPlaying>());
      expect((event! as ViewerPlaying).index, 3);
    });

    test('error con su mensaje', () {
      final event = parseViewerEvent('{"type":"error","message":"sin WebGL"}');

      expect((event! as ViewerError).message, 'sin WebGL');
    });

    test('un tipo desconocido se ignora', () {
      expect(parseViewerEvent('{"type":"otro"}'), isNull);
    });

    test('un JSON roto se ignora', () {
      expect(parseViewerEvent('{"type":'), isNull);
    });

    test('playing sin índice se ignora', () {
      expect(parseViewerEvent('{"type":"playing"}'), isNull);
    });
  });

  group('órdenes', () {
    test('loadCommand lleva el plan', () {
      const plan = ChainPlan(
        steps: [PlannedStep(clip: 'Globo', playable: true, offsetX: 0, offsetZ: 0, startX: 1, startZ: 2)],
        bounds: FloorBounds(minX: 0, maxX: 1, minZ: 0, maxZ: 2),
      );

      final command = loadCommand(plan);

      expect(command, startsWith('ppLoad('));
      expect(command, contains('"clip":"Globo"'));
    });

    test('goToCommand', () {
      expect(goToCommand(2), 'ppGoTo(2)');
    });

    test('pausa y reanudar', () {
      expect(pauseCommand, 'ppPause()');
      expect(resumeCommand, 'ppResume()');
    });
  });
}
