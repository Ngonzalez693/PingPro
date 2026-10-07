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

  group('passwordChangeErrorMessage', () {
    test('la contraseña actual incorrecta se explica igual en ambos códigos', () {
      expect(passwordChangeErrorMessage('wrong-password'), 'La contraseña actual no es correcta');
      expect(passwordChangeErrorMessage('invalid-credential'), 'La contraseña actual no es correcta');
    });

    test('traduce los demás errores que el usuario puede resolver', () {
      expect(passwordChangeErrorMessage('weak-password'), 'La nueva contraseña es demasiado débil');
      expect(passwordChangeErrorMessage('too-many-requests'), 'Demasiados intentos, prueba más tarde');
      expect(passwordChangeErrorMessage('network-request-failed'), 'Sin conexión, revisa tu red');
    });

    test('cualquier otro código cae en un mensaje genérico', () {
      expect(
        passwordChangeErrorMessage('internal-error'),
        'No se pudo cambiar la contraseña, inténtalo de nuevo',
      );
    });
  });

  group('validateNewPassword', () {
    test('acepta una contraseña de 6 o más caracteres repetida igual', () {
      expect(validateNewPassword('abc123', 'abc123'), isNull);
    });

    test('rechaza menos de 6 caracteres', () {
      expect(validateNewPassword('abc12', 'abc12'), 'La nueva contraseña debe tener al menos 6 caracteres');
    });

    test('rechaza si la repetición no coincide', () {
      expect(validateNewPassword('abc123', 'abc124'), 'Las contraseñas no coinciden');
    });
  });

  group('accountDeletionErrorMessage', () {
    test('la contraseña incorrecta se explica igual en ambos códigos', () {
      expect(accountDeletionErrorMessage('wrong-password'), 'La contraseña actual no es correcta');
      expect(accountDeletionErrorMessage('invalid-credential'), 'La contraseña actual no es correcta');
    });

    test('comparte con cambiar contraseña los mensajes de intentos y de red', () {
      expect(accountDeletionErrorMessage('too-many-requests'), 'Demasiados intentos, prueba más tarde');
      expect(accountDeletionErrorMessage('network-request-failed'), 'Sin conexión, revisa tu red');
    });

    test('weak-password no aplica al eliminar: cae en el genérico', () {
      expect(
        accountDeletionErrorMessage('weak-password'),
        'No se pudo eliminar la cuenta, inténtalo de nuevo',
      );
    });

    test('cualquier otro código cae en el genérico', () {
      expect(
        accountDeletionErrorMessage('internal-error'),
        'No se pudo eliminar la cuenta, inténtalo de nuevo',
      );
    });
  });
}
