import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/api_responses.dart';

void main() {
  group('parseCreatedId', () {
    test('lee el id de la respuesta real del backend', () {
      expect(parseCreatedId({'success': true, 'data': {'id': 'abc-123'}}), 'abc-123');
    });

    test('sin un id utilizable devuelve null', () {
      expect(parseCreatedId(null), isNull);
      expect(parseCreatedId({'success': true}), isNull);
      expect(parseCreatedId({'data': {'id': ''}}), isNull);
      expect(parseCreatedId({'data': {'id': 42}}), isNull);
    });
  });
}
