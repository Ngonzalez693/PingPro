import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/viewer/animation_file_cache.dart';

const _url = 'https://cdn.test/v1/PingProAnimations.glb';
const _otherUrl = 'https://cdn.test/v2/PingProAnimations.glb';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('animation_cache_test'));
  tearDown(() async => dir.delete(recursive: true));

  List<String> filesIn(Directory d) => d.listSync().map((e) => e.uri.pathSegments.last).toList();

  test('la primera vez descarga y la segunda usa el archivo guardado', () async {
    var calls = 0;
    final cache = AnimationFileCache(
      directory: dir,
      client: MockClient((_) async {
        calls++;
        return http.Response.bytes([1, 2, 3], 200);
      }),
    );

    final first = await cache.fileFor(_url);
    final second = await cache.fileFor(_url);

    expect(calls, 1);
    expect(second.path, first.path);
    expect(await second.readAsBytes(), [1, 2, 3]);
  });

  test('otra URL descarga de nuevo y borra la anterior', () async {
    final cache = AnimationFileCache(
      directory: dir,
      client: MockClient((req) async => http.Response.bytes(req.url == Uri.parse(_url) ? [1] : [2], 200)),
    );

    final old = await cache.fileFor(_url);
    final fresh = await cache.fileFor(_otherUrl);

    expect(await fresh.readAsBytes(), [2]);
    expect(old.existsSync(), isFalse);
    expect(filesIn(dir).where((f) => f.endsWith('.glb')), hasLength(1));
  });

  test('una descarga que falla a medias no deja archivo', () async {
    final broken = AnimationFileCache(
      directory: dir,
      client: MockClient.streaming((_, __) async {
        final body = StreamController<List<int>>();
        body.add([1, 2]);
        body.addError(const SocketException('se cortó'));
        unawaited(body.close());
        return http.StreamedResponse(body.stream, 200);
      }),
    );

    await expectLater(broken.fileFor(_url), throwsA(isA<SocketException>()));
    expect(filesIn(dir), isEmpty);

    final healthy = AnimationFileCache(
      directory: dir,
      client: MockClient((_) async => http.Response.bytes([7], 200)),
    );
    expect(await (await healthy.fileFor(_url)).readAsBytes(), [7]);
  });

  test('un cuerpo que se queda parado falla por tiempo', () async {
    final body = StreamController<List<int>>();
    final cache = AnimationFileCache(
      directory: dir,
      idleTimeout: const Duration(milliseconds: 50),
      client: MockClient.streaming((_, __) async {
        body.add([1]);
        return http.StreamedResponse(body.stream, 200);
      }),
    );

    await expectLater(cache.fileFor(_url), throwsA(isA<TimeoutException>()));
    expect(filesIn(dir), isEmpty);
    await body.close();
  });

  test('un error del servidor no guarda nada', () async {
    final cache = AnimationFileCache(
      directory: dir,
      client: MockClient((_) async => http.Response('no', 404)),
    );

    Object? error;
    try {
      await cache.fileFor(_url);
    } on AnimationDownloadException catch (e) {
      error = e;
    }

    expect(error, isA<AnimationDownloadException>());
    expect(loadErrorMessage(error!), loadFailedMessage);
    expect(filesIn(dir), isEmpty);
  });

  test('sin red el mensaje es el de sin conexión', () async {
    final cache = AnimationFileCache(
      directory: dir,
      client: MockClient((_) async => throw http.ClientException('Failed host lookup')),
    );

    Object? error;
    try {
      await cache.fileFor(_url);
    } on http.ClientException catch (e) {
      error = e;
    }

    expect(loadErrorMessage(error!), noConnectionMessage);
  });

  test('dos pedidos a la vez comparten la descarga', () async {
    var calls = 0;
    final release = Completer<void>();
    final cache = AnimationFileCache(
      directory: dir,
      client: MockClient((_) async {
        calls++;
        await release.future;
        return http.Response.bytes([1], 200);
      }),
    );

    final a = cache.fileFor(_url);
    final b = cache.fileFor(_url);
    release.complete();

    expect((await a).path, (await b).path);
    expect(calls, 1);
  });
}
