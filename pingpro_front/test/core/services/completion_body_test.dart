import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/completion_body.dart';

void main() {
  test('con sesión la envía junto a completed', () {
    expect(completionBody(true, 2), {'completed': true, 'session': 2});
  });

  test('sin sesión envía solo completed, como la app anterior', () {
    expect(completionBody(true, null), {'completed': true});
    expect(completionBody(false, null), {'completed': false});
  });
}
