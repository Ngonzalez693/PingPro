import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

FirebaseAuthException _auth(String code) => FirebaseAuthException(code: code);

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

  group('loginErrorMessage', () {
    test('sin red es el mensaje de sin conexión', () {
      expect(loginErrorMessage(_auth('network-request-failed')), noConnectionMessage);
    });

    // Con la protección de enumeración Firebase devuelve invalid-credential
    // en vez de decir cuál de los dos está mal.
    test('email o contraseña incorrectos, sea cual sea el código', () {
      for (final code in ['invalid-credential', 'wrong-password', 'user-not-found']) {
        expect(loginErrorMessage(_auth(code)), 'Email o contraseña incorrectos');
      }
    });

    test('demasiados intentos', () {
      expect(loginErrorMessage(_auth('too-many-requests')), 'Demasiados intentos, prueba más tarde');
    });

    test('cualquier otro error cae en el genérico, nunca en el texto de Firebase', () {
      expect(loginErrorMessage(_auth('internal-error')), 'No se pudo iniciar sesión, inténtalo de nuevo');
      expect(loginErrorMessage(Exception('boom')), 'No se pudo iniciar sesión, inténtalo de nuevo');
    });
  });

  group('registerErrorMessage', () {
    test('sin red, al llamar al backend o a Firebase, es el mensaje de sin conexión', () {
      expect(registerErrorMessage(http.ClientException('Failed host lookup')), noConnectionMessage);
      expect(registerErrorMessage(_auth('network-request-failed')), noConnectionMessage);
    });

    // Si el email ya existía, el registro intenta iniciar sesión con él; que
    // la contraseña no encaje significa que la cuenta es de antes.
    test('un email con cuenta y otra contraseña lo explica', () {
      expect(
        registerErrorMessage(_auth('invalid-credential')),
        'Ese email ya tiene una cuenta. Inicia sesión o recupera tu contraseña.',
      );
    });

    test('el texto en inglés del servidor nunca llega al usuario', () {
      expect(
        registerErrorMessage(Exception('The password must be a string with at least 6 characters.')),
        'No se pudo crear la cuenta, inténtalo de nuevo',
      );
    });
  });

  group('validateSignupPassword', () {
    test('acepta 6 o más caracteres', () {
      expect(validateSignupPassword('123456'), isNull);
    });

    test('rechaza menos de 6, el mínimo de Firebase', () {
      expect(validateSignupPassword('12345'), 'La contraseña debe tener al menos 6 caracteres');
    });
  });
}
