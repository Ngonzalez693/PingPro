import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/refresh_user.dart';

void main() {
  test('recarga el usuario', () async {
    var reloads = 0;

    await refreshUser(() async => reloads++);

    expect(reloads, 1);
  });

  // Sin conexión reload() falla: la pestaña Perfil tiene que redibujarse igual.
  test('si recargar falla, no lanza', () async {
    await expectLater(refreshUser(() async => throw Exception('network-request-failed')), completes);
  });

  test('sin usuario no hace nada', () async {
    await expectLater(refreshUser(null), completes);
  });
}
