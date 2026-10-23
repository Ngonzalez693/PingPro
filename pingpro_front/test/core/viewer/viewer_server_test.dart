import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/viewer/viewer_server.dart';

// Los assets falsos devuelven su propia clave como texto: así se ve qué
// archivo sirvió el servidor para cada ruta.
Future<ByteData> _fakeAsset(String key) async =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode('asset:$key')));

void main() {
  late Directory tmp;
  late File glb;
  late ViewerServer server;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('viewer_server_test');
    glb = File('${tmp.path}/a.glb')..writeAsBytesSync([1, 2, 3]);
    server = await ViewerServer.start(loadAsset: _fakeAsset, animationFile: glb);
  });

  tearDown(() async {
    await server.close();
    await tmp.delete(recursive: true);
  });

  Uri at(String path) => server.pageUri.replace(path: path);

  test('sirve la página en /', () async {
    final r = await http.get(server.pageUri);

    expect(server.pageUri.host, '127.0.0.1');
    expect(r.statusCode, 200);
    expect(r.body, 'asset:assets/viewer/viewer.html');
    expect(r.headers['content-type'], startsWith('text/html'));
  });

  test('sirve los .js con tipo javascript', () async {
    final r = await http.get(at('/three.module.min.js'));

    expect(r.statusCode, 200);
    expect(r.body, 'asset:assets/viewer/three.module.min.js');
    expect(r.headers['content-type'], startsWith('text/javascript'));
  });

  test('sirve el archivo de animaciones', () async {
    final r = await http.get(at('/animations.glb'));

    expect(r.statusCode, 200);
    expect(r.bodyBytes, [1, 2, 3]);
    expect(r.headers['content-type'], 'model/gltf-binary');
  });

  test('cualquier otra ruta es 404', () async {
    expect((await http.get(at('/../secret'))).statusCode, 404);
    expect((await http.get(at('/nada.js'))).statusCode, 404);
  });

  test('close libera el puerto', () async {
    final uri = server.pageUri;
    await server.close();

    expect(
      http.get(uri),
      throwsA(anyOf(isA<SocketException>(), isA<http.ClientException>())),
    );
  });
}
