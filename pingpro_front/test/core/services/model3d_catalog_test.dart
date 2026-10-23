import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/services/model3d_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://cdn.test/v2/PingProAnimations.glb';

void main() {
  test('con red devuelve la URL del servidor y la recuerda', () async {
    SharedPreferences.setMockInitialValues({});

    final url = await Model3dCatalog.withFetcher(() async => _url).animationsUrl();

    expect(url, _url);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('animationsUrl'), _url);
  });

  // El archivo ya está en el teléfono: sin red se sigue pudiendo abrir.
  test('sin red usa la última URL recordada', () async {
    SharedPreferences.setMockInitialValues({'animationsUrl': _url});

    final url = await Model3dCatalog.withFetcher(() async => throw http.ClientException('Failed host lookup'))
        .animationsUrl();

    expect(url, _url);
  });

  test('sin red y sin URL recordada falla con el error de red', () async {
    SharedPreferences.setMockInitialValues({});

    expect(
      Model3dCatalog.withFetcher(() async => throw http.ClientException('Failed host lookup')).animationsUrl(),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('si el servidor dice que no hay archivo no se usa la recordada', () async {
    SharedPreferences.setMockInitialValues({'animationsUrl': _url});

    expect(await Model3dCatalog.withFetcher(() async => null).animationsUrl(), isNull);
  });
}
