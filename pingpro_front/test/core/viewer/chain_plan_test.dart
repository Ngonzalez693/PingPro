import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/viewer/chain_plan.dart';
import 'package:pingpro_front/core/viewer/glb_floor_tracks.dart';

FloorTrack _track({
  required double startX,
  required double startZ,
  required double endX,
  required double endZ,
  double? minX,
  double? maxX,
  double? minZ,
  double? maxZ,
}) =>
    FloorTrack(
      startX: startX,
      startZ: startZ,
      endX: endX,
      endZ: endZ,
      minX: minX ?? (startX < endX ? startX : endX),
      maxX: maxX ?? (startX > endX ? startX : endX),
      minZ: minZ ?? (startZ < endZ ? startZ : endZ),
      maxZ: maxZ ?? (startZ > endZ ? startZ : endZ),
    );

final _a = _track(startX: 0, startZ: 0, endX: 2, endZ: 1, minX: 0, maxX: 2);
final _b = _track(startX: 5, startZ: 5, endX: 6, endZ: 5, minX: 5, maxX: 6);
final _tracks = {'A': _a, 'B': _b};

void main() {
  test('el primer paso queda donde se grabó', () {
    final first = buildChainPlan(['A'], _tracks).steps.single;

    expect([first.offsetX, first.offsetZ], [0, 0]);
  });

  test('cada paso empieza donde terminó el anterior', () {
    final b = buildChainPlan(['A', 'B'], _tracks).steps[1];

    expect([b.offsetX, b.offsetZ], [-3, -4]);
    expect([b.startX + b.offsetX, b.startZ + b.offsetZ], [_a.endX, _a.endZ]);
  });

  test('un clip que falta se salta y no corta la cadena', () {
    final steps = buildChainPlan(['A', 'X', 'B'], _tracks).steps;

    expect(steps[1].playable, isFalse);
    expect([steps[1].offsetX, steps[1].offsetZ], [0, 0]);
    expect([steps[2].offsetX, steps[2].offsetZ], [-3, -4]);
  });

  test('los límites cubren una pasada completa', () {
    final bounds = buildChainPlan(['A', 'B'], _tracks).bounds!;

    expect([bounds.minX, bounds.maxX], [0, 3]);
    expect([bounds.minZ, bounds.maxZ], [0, 1]);
  });

  // Al volver a empezar el bucle se usa otra vez el desplazamiento del paso 0,
  // así que una sola pasada describe todo lo que se verá.
  test('un solo clip en bucle no se desplaza', () {
    final plan = buildChainPlan(['A'], _tracks);

    expect([plan.steps.single.offsetX, plan.steps.single.offsetZ], [0, 0]);
    expect([plan.bounds!.minX, plan.bounds!.maxX, plan.bounds!.minZ, plan.bounds!.maxZ], [0, 2, 0, 1]);
  });

  test('sin ningún clip disponible no es reproducible', () {
    final plan = buildChainPlan(['X', 'Y'], _tracks);

    expect(plan.playable, isFalse);
    expect(plan.bounds, isNull);
  });

  test('toJson de un paso trae lo que necesita el visor', () {
    final json = buildChainPlan(['A', 'B'], _tracks).toJson();
    final step = (json['steps'] as List)[1] as Map;

    expect(step.keys, unorderedEquals(['clip', 'playable', 'offsetX', 'offsetZ', 'startX', 'startZ']));
    expect(step['clip'], 'B');
    expect((json['bounds'] as Map).keys, unorderedEquals(['minX', 'maxX', 'minZ', 'maxZ']));
  });
}
