import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

void main() {
  final json = {'hit': 1, 'rotation': 2, 'zone': 3, 'direction': 6, 'side': 1};

  test('lee la profundidad propia', () {
    expect(SequenceStep.fromJson({...json, 'ownZone': 3}).ownZone, ZoneCode.long);
  });

  test('sin profundidad propia queda en Libre', () {
    expect(SequenceStep.fromJson(json).ownZone, ZoneCode.free);
  });

  test('la envía al backend', () {
    final step = SequenceStep.fromJson({...json, 'ownZone': 1});

    expect(step.toJson(), {...json, 'ownZone': 1});
  });
}
