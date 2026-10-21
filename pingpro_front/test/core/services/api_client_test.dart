import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pingpro_front/core/services/api_client.dart';

final _uri = Uri.parse('https://api.test/api/exercises');

void main() {
  test('una respuesta normal pasa tal cual', () async {
    final client = TimeoutClient(MockClient((_) async => http.Response('ok', 200)));

    final response = await client.get(_uri);

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });

  // testWidgets corre con reloj falso: pump(d) adelanta el tiempo sin esperar.
  testWidgets('una petición que no responde falla al llegar al límite', (tester) async {
    final client = TimeoutClient(MockClient((_) => Completer<http.Response>().future));
    Object? error;
    unawaited(client.get(_uri).then((_) {}, onError: (Object e) => error = e));

    await tester.pump(requestTimeout - const Duration(milliseconds: 1));
    expect(error, isNull);

    await tester.pump(const Duration(milliseconds: 1));
    expect(error, isA<TimeoutException>());
  });

  // Pedir el ID token de Firebase va antes de la petición y sin red también
  // puede quedarse colgado.
  testWidgets('withRequestTimeout corta igual un paso previo que no termina', (tester) async {
    Object? error;
    unawaited(withRequestTimeout(Completer<String>().future).then((_) {}, onError: (Object e) => error = e));

    await tester.pump(requestTimeout - const Duration(milliseconds: 1));
    expect(error, isNull);

    await tester.pump(const Duration(milliseconds: 1));
    expect(error, isA<TimeoutException>());
  });

  test('withRequestTimeout deja pasar lo que termina a tiempo', () async {
    expect(await withRequestTimeout(Future.value('token')), 'token');
  });

  test('el límite es de 15 segundos', () {
    expect(requestTimeout, const Duration(seconds: 15));
  });
}
