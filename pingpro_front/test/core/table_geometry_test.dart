import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/table_geometry.dart';

void main() {
  group('strokeOrigins', () {
    test('hay 12: fila larga, fila corta y las dos bandas', () {
      expect(strokeOrigins, hasLength(12));
    });

    test('todos están en el campo del jugador', () {
      expect(strokeOrigins.every((o) => o.position.dy > netY), isTrue);
    });

    test('la derecha de la pantalla es la derecha del jugador', () {
      expect(strokeOrigins[4].side, 1); // fila larga, derecha = esquina derecha
      expect(strokeOrigins[0].side, 5); // fila larga, izquierda = esquina izquierda
    });

    test('la fila corta guarda el mismo lado que la larga de su columna', () {
      for (var column = 0; column < 5; column++) {
        expect(strokeOrigins[5 + column].side, strokeOrigins[column].side);
        expect(strokeOrigins[5 + column].position.dx, strokeOrigins[column].position.dx);
      }
    });

    test('la fila corta está más cerca de la red que la larga', () {
      expect(strokeOrigins[5].position.dy, lessThan(strokeOrigins[0].position.dy));
    });

    test('las bandas guardan el lado de su esquina', () {
      expect(strokeOrigins[10].position.dx, 0);
      expect(strokeOrigins[10].side, 5);
      expect(strokeOrigins[11].position.dx, 1);
      expect(strokeOrigins[11].side, 1);
    });

    test('la profundidad propia sale de la fila: larga, corta o banda', () {
      for (var column = 0; column < 5; column++) {
        expect(strokeOrigins[column].ownZone, 3); // fila larga = Largo
        expect(strokeOrigins[5 + column].ownZone, 1); // fila corta = Corto
      }
      expect(strokeOrigins[10].ownZone, 2); // bandas = Intermedio
      expect(strokeOrigins[11].ownZone, 2);
    });
  });

  group('strokeTargets', () {
    test('hay 17: filas larga, media y corta, y las dos bandas', () {
      expect(strokeTargets, hasLength(17));
    });

    test('todos están en el campo del rival', () {
      expect(strokeTargets.every((t) => t.position.dy < netY), isTrue);
    });

    test('intermedio existe en todas las columnas, no solo en las bandas', () {
      final middleDirections = strokeTargets.where((t) => t.zone == 2).map((t) => t.direction).toSet();

      expect(middleDirections, containsAll([2, 3, 4, 5, 6]));
    });

    test('ningún destino produce "libre"', () {
      expect(strokeTargets.any((t) => t.direction == 8 || t.zone == 4), isFalse);
    });

    test('las filas cortas de ambos lados son reflejo una de otra', () {
      final shortOrigin = strokeOrigins[5].position.dy - netY;
      final shortTarget = netY - strokeTargets.firstWhere((t) => t.zone == 1).position.dy;

      expect(shortTarget, closeTo(shortOrigin, 0.0001));
    });
  });

  group('snapTarget', () {
    test('se engancha al destino más cercano', () {
      final target = snapTarget(const Offset(0.08, 0.06))!;

      expect((target.direction, target.zone), (6, 3)); // esquina izquierda, largo
    });

    test('la fila media da intermedio', () {
      final target = snapTarget(const Offset(0.5, 0.26))!;

      expect((target.direction, target.zone), (4, 2)); // medio, intermedio
    });

    test('junto a la red da corto', () {
      final target = snapTarget(const Offset(0.9, 0.44))!;

      expect((target.direction, target.zone), (2, 1)); // esquina derecha, corto
    });

    test('fuera de la banda, a media altura, da la lateral', () {
      expect(snapTarget(const Offset(-0.1, 0.245))!.direction, 7);
      expect(snapTarget(const Offset(1.1, 0.245))!.direction, 1);
    });

    test('más allá del fondo del rival se engancha a la fila larga', () {
      expect(snapTarget(const Offset(0.5, -0.3))!.zone, 3);
    });

    test('en tu propio campo no se engancha a nada', () {
      expect(snapTarget(const Offset(0.5, 0.5)), isNull);
      expect(snapTarget(const Offset(0.5, 0.8)), isNull);
    });
  });

  group('tableRectFor', () {
    test('respeta las proporciones de una mesa reglamentaria', () {
      final rect = tableRectFor(const Size(400, 800));

      expect(rect.width / rect.height, closeTo(tableAspectRatio, 0.0001));
    });

    test('deja hueco a los lados para los puntos de las bandas', () {
      final rect = tableRectFor(const Size(400, 800));

      expect(rect.left, greaterThan(0));
      expect(rect.right, lessThan(400));
    });

    test('en un lienzo bajo se ajusta por la altura y no se sale', () {
      final rect = tableRectFor(const Size(400, 300));

      expect(rect.height, 300);
      expect(rect.width, lessThan(400));
    });

    test('queda centrada', () {
      final rect = tableRectFor(const Size(400, 800));

      expect(rect.center.dx, closeTo(200, 0.001));
      expect(rect.center.dy, closeTo(400, 0.001));
    });
  });

  group('conversión píxeles ↔ mesa', () {
    const table = Rect.fromLTWH(50, 100, 200, 360);

    test('toCanvas y toTable son inversas', () {
      const point = Offset(0.3, 0.7);

      final back = toTable(toCanvas(point, table), table);

      expect(back.dx, closeTo(point.dx, 0.0001));
      expect(back.dy, closeTo(point.dy, 0.0001));
    });

    test('fuera de la mesa sale de 0..1', () {
      expect(toTable(const Offset(20, 200), table).dx, lessThan(0));
    });
  });

  group('originAt', () {
    const table = Rect.fromLTWH(0, 0, 250, 450);

    test('encuentra el punto de golpeo bajo el dedo', () {
      final center = toCanvas(strokeOrigins[7].position, table);

      expect(originAt(center + const Offset(5, -5), table, 24), 7);
    });

    test('lejos de todos no devuelve ninguno', () {
      expect(originAt(const Offset(125, 100), table, 24), isNull);
    });
  });
}
