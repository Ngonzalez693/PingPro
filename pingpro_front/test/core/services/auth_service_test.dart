import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

void main() {
  group('hasAdminRole', () {
    test('con el rol admin es admin', () {
      expect(hasAdminRole({'roles': ['admin']}), isTrue);
      expect(hasAdminRole({'roles': ['user', 'admin']}), isTrue);
    });

    test('con otros roles no lo es', () {
      expect(hasAdminRole({'roles': ['user']}), isFalse);
      expect(hasAdminRole({'roles': []}), isFalse);
    });

    test('un perfil vacío, que es lo que llega si falla la petición, no es admin', () {
      expect(hasAdminRole({}), isFalse);
    });

    test('roles con un formato inesperado no cuenta como admin', () {
      expect(hasAdminRole({'roles': 'admin'}), isFalse);
      expect(hasAdminRole({'roles': null}), isFalse);
    });
  });

  group('passwordResetErrorMessage', () {
    test('traduce los errores que el usuario puede resolver', () {
      expect(passwordResetErrorMessage('invalid-email'), 'Email no válido');
      expect(
        passwordResetErrorMessage('too-many-requests'),
        'Demasiados intentos, prueba más tarde',
      );
      expect(
        passwordResetErrorMessage('network-request-failed'),
        'Sin conexión, revisa tu red',
      );
    });

    test('cualquier otro código cae en un mensaje genérico', () {
      expect(
        passwordResetErrorMessage('internal-error'),
        'No se pudo enviar el correo, inténtalo de nuevo',
      );
    });
  });
}
