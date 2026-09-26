import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/email_validation.dart';

void main() {
  group('isValidEmail', () {
    test('acepta emails con usuario, dominio y extensión', () {
      expect(isValidEmail('ana@pingpro.com'), isTrue);
      expect(isValidEmail('ana.perez+tt@mail.pingpro.co'), isTrue);
    });

    test('rechaza lo que no tiene arroba o dominio', () {
      expect(isValidEmail('ana'), isFalse);
      expect(isValidEmail('ana@'), isFalse);
      expect(isValidEmail('@pingpro.com'), isFalse);
    });

    test('rechaza un dominio sin extensión', () {
      expect(isValidEmail('ana@pingpro'), isFalse);
    });

    test('rechaza espacios y arrobas de más', () {
      expect(isValidEmail('ana perez@pingpro.com'), isFalse);
      expect(isValidEmail('ana@@pingpro.com'), isFalse);
    });

    test('un texto vacío no es un email', () {
      expect(isValidEmail(''), isFalse);
    });
  });
}
