import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/session_roles.dart';

void main() {
  group('SessionRoles', () {
    test('pide el perfil una sola vez por sesión', () async {
      var calls = 0;
      final roles = SessionRoles(() async {
        calls++;
        return {'roles': ['admin']};
      });

      expect(await roles.isAdmin(), isTrue);
      expect(await roles.isAdmin(), isTrue);
      expect(calls, 1);
    });

    test('sin el rol admin no es admin', () async {
      final roles = SessionRoles(() async => {'roles': ['user']});

      expect(await roles.isAdmin(), isFalse);
    });

    test('un perfil vacío (la petición falló) no se guarda y se reintenta', () async {
      var calls = 0;
      final roles = SessionRoles(() async {
        calls++;
        return <String, dynamic>{};
      });

      expect(await roles.isAdmin(), isFalse);
      await roles.isAdmin();
      expect(calls, 2);
    });

    test('un error cuenta como no admin y se reintenta', () async {
      var calls = 0;
      final roles = SessionRoles(() async {
        calls++;
        throw Exception('sin red');
      });

      expect(await roles.isAdmin(), isFalse);
      await roles.isAdmin();
      expect(calls, 2);
    });

    test('reset obliga a pedirlo otra vez (cambio de usuario)', () async {
      var calls = 0;
      final roles = SessionRoles(() async {
        calls++;
        return {'roles': ['admin']};
      });

      await roles.isAdmin();
      roles.reset();
      await roles.isAdmin();
      expect(calls, 2);
    });

    test('dos isAdmin() antes de que la petición termine comparten la misma petición', () async {
      var calls = 0;
      final completer = Completer<Map<String, dynamic>>();
      final roles = SessionRoles(() {
        calls++;
        return completer.future;
      });

      // Lanzar dos isAdmin() sin esperar: ambos usan ??= así que solo uno
      // ejecuta _load() (que inicia la fetción)
      final future1 = roles.isAdmin();
      final future2 = roles.isAdmin();

      // Ambas apuntan a la misma Future
      expect(identical(future1, future2), isTrue);

      // Completar la petición
      completer.complete({'roles': ['admin']});
      expect(await future1, isTrue);
      expect(await future2, isTrue);
      // El fetcher se llamó una sola vez
      expect(calls, 1);
    });

    test('reset() durante una petición en vuelo: la siguiente petición es nueva', () async {
      var calls = 0;
      final completer1 = Completer<Map<String, dynamic>>();
      final completer2 = Completer<Map<String, dynamic>>();
      int callIndex = 0;

      final roles = SessionRoles(() {
        calls++;
        callIndex++;
        if (callIndex == 1) return completer1.future;
        return completer2.future;
      });

      // Lanzar isAdmin()
      final future1 = roles.isAdmin();

      // Resetear antes de que complete
      roles.reset();

      // Lanzar otra isAdmin() - crea una nueva Future
      final future2 = roles.isAdmin();

      // Dos Futures diferentes
      expect(identical(future1, future2), isFalse);

      // Completar cada una con un resultado diferente
      completer1.complete({'roles': ['user']});
      completer2.complete({'roles': ['admin']});

      // future1 viene de la primera petición (usuario no admin)
      expect(await future1, isFalse);
      // future2 viene de la segunda petición (usuario admin)
      expect(await future2, isTrue);
      // El fetcher se llamó dos veces
      expect(calls, 2);
    });

    test('un fetcher que lanza síncronamente se reintenta en la próxima llamada', () async {
      var calls = 0;
      final roles = SessionRoles(() {
        calls++;
        throw TypeError();
      });

      expect(await roles.isAdmin(), isFalse);
      expect(await roles.isAdmin(), isFalse);
      expect(calls, 2);
    });
  });

  test('canManage: lo propio siempre; el catálogo solo si eres admin', () {
    expect(canManage(isOwn: true, isAdmin: false), isTrue);
    expect(canManage(isOwn: false, isAdmin: true), isTrue);
    expect(canManage(isOwn: false, isAdmin: false), isFalse);
  });
}
