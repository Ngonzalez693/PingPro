import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/api_errors.dart';

void main() {
  group('backendErrorMessage', () {
    test('lee message, que es lo que mandan los controladores', () {
      expect(backendErrorMessage('{"success":false,"message":"Exercise not found"}', 'x'), 'Exercise not found');
    });

    test('lee error, que es lo que mandan Joi y el authMiddleware', () {
      expect(backendErrorMessage('{"error":"\\"name\\" is required"}', 'x'), '"name" is required');
    });

    test('sin ninguno de los dos usa el mensaje por defecto', () {
      expect(backendErrorMessage('{"success":false}', 'No se pudo'), 'No se pudo');
    });

    test('un cuerpo que no es JSON no rompe: usa el mensaje por defecto', () {
      expect(backendErrorMessage('<html>502 Bad Gateway</html>', 'No se pudo'), 'No se pudo');
    });
  });
}
