// Servidor HTTP local (solo 127.0.0.1) que sirve el visor 3D al WebView: la
// página, three.js y el archivo de animaciones guardado en el teléfono.
//
// Por qué un servidor y no cargar la página como archivo: three.js se carga
// como módulos ES, y el WebView de Android no los admite desde file://.
// network_security_config ya permite HTTP sin cifrar solo hacia 127.0.0.1.
//
// three.js es la versión 0.160.0 de npm, copiada tal cual a assets/viewer/
// (paquete con integridad sha512-DLU8lc0zNIPkM7rH5/e1Ks1Z8tWCGRq6g8mPowdDJpw1CFBJMU7UoJjC6PefXW7z//SSl0b2+GCw14LB+uDhng==).
//
// Solo responde a una lista fija de nombres: la ruta pedida nunca se usa
// para construir una ruta de archivo.
import 'dart:io';

import 'package:flutter/foundation.dart';

const _html = 'text/html; charset=utf-8';
const _javascript = 'text/javascript; charset=utf-8';
const _glb = 'model/gltf-binary';

const _assets = {
  '/': ('assets/viewer/viewer.html', _html),
  '/viewer.js': ('assets/viewer/viewer.js', _javascript),
  '/three.module.min.js': ('assets/viewer/three.module.min.js', _javascript),
  '/GLTFLoader.js': ('assets/viewer/GLTFLoader.js', _javascript),
  '/BufferGeometryUtils.js': ('assets/viewer/BufferGeometryUtils.js', _javascript),
  '/OrbitControls.js': ('assets/viewer/OrbitControls.js', _javascript),
};

class ViewerServer {
  final HttpServer _server;
  final Future<ByteData> Function(String assetKey) _loadAsset;
  final File _animationFile;

  ViewerServer._(this._server, this._loadAsset, this._animationFile);

  static Future<ViewerServer> start({
    required Future<ByteData> Function(String assetKey) loadAsset,
    required File animationFile,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final viewer = ViewerServer._(server, loadAsset, animationFile);
    server.listen(viewer._handle, onError: (Object e) => debugPrint('Visor 3D: servidor local: $e'));
    return viewer;
  }

  Uri get pageUri => Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: '/');

  Future<void> close() => _server.close(force: true);

  // Cada apertura usa otro puerto, así que para el WebView cada vez es otro
  // sitio: sin no-store guardaría una copia del archivo (~4 MB) por apertura.
  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    try {
      await _respond(request.uri.path, response);
    } on Object catch (e) {
      debugPrint('Visor 3D: no se pudo servir ${request.uri.path}: $e');
      _markFailed(response);
    }
    try {
      await response.close();
    } on Object catch (e) {
      debugPrint('Visor 3D: conexión cerrada a medias: $e');
    }
  }

  // Si el cuerpo ya empezó a salir, el estado no se puede cambiar: la página
  // verá la respuesta cortada y lo tratará como error de carga.
  void _markFailed(HttpResponse response) {
    try {
      response.statusCode = HttpStatus.internalServerError;
    } on StateError catch (e) {
      debugPrint('Visor 3D: respuesta ya empezada, se corta: $e');
    }
  }

  Future<void> _respond(String path, HttpResponse response) async {
    if (path == '/animations.glb' && await _animationFile.exists()) {
      response.headers.set(HttpHeaders.contentTypeHeader, _glb);
      await response.addStream(_animationFile.openRead());
    } else if (_assets[path] case (final key, final type)) {
      final data = await _loadAsset(key);
      response.headers.set(HttpHeaders.contentTypeHeader, type);
      response.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } else {
      response.statusCode = HttpStatus.notFound;
    }
  }
}
