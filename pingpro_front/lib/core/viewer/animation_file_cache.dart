// El archivo de animaciones (.glb, ~4 MB) guardado en el teléfono: se baja la
// primera vez y luego se reutiliza, también sin conexión.
//
// Se guarda por URL: si se suben animaciones mejores, la URL cambia (las de
// Cloudinary llevan versión), se baja el nuevo y se borra el anterior, así la
// carpeta nunca crece. La carpeta es la de caché de la app (en Android,
// Directory.systemTemp): si el sistema la vacía, simplemente se vuelve a bajar.
//
// La descarga se escribe primero en un .part y solo al terminar se renombra:
// un archivo a medias (red cortada, app cerrada) nunca se usa.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/services/api_client.dart';

/// El servidor respondió, pero sin el archivo. No es un error de conexión.
class AnimationDownloadException implements Exception {
  final int statusCode;

  const AnimationDownloadException(this.statusCode);

  @override
  String toString() => 'AnimationDownloadException: HTTP $statusCode';
}

class AnimationFileCache {
  final Directory _directory;
  final http.Client _client;

  /// Cuánto puede tardar en llegar el siguiente trozo del archivo: el límite
  /// de apiClient solo cubre hasta las cabeceras.
  final Duration idleTimeout;

  final Map<String, Future<File>> _inFlight = {};

  AnimationFileCache({Directory? directory, http.Client? client, this.idleTimeout = requestTimeout})
      : _directory = directory ?? Directory('${Directory.systemTemp.path}/pingpro_animations'),
        _client = client ?? apiClient;

  static final AnimationFileCache instance = AnimationFileCache();

  /// El archivo de [url] en el teléfono, bajándolo si todavía no está. Dos
  /// pantallas que lo piden a la vez comparten la misma descarga.
  Future<File> fileFor(String url) {
    final pending = _inFlight[url];
    if (pending != null) return pending;
    // Cuerpo con llaves a propósito: remove() devuelve este mismo Future y
    // whenComplete esperaría a que terminara él mismo, sin fin.
    final future = _obtain(url).whenComplete(() {
      _inFlight.remove(url);
    });
    _inFlight[url] = future;
    return future;
  }

  /// Borra el archivo guardado de [url] (p. ej. porque resultó ilegible), para
  /// que el siguiente [fileFor] lo vuelva a bajar.
  Future<void> evict(String url) async {
    final file = _fileFor(url);
    if (await file.exists()) await file.delete();
  }

  File _fileFor(String url) => File('${_directory.path}/${_fnv1a(url)}.glb');

  Future<File> _obtain(String url) async {
    final file = _fileFor(url);
    if (await file.exists()) return file;
    await _directory.create(recursive: true);
    final part = File('${file.path}.part');
    try {
      await _download(url, part);
    } on Object {
      if (await part.exists()) await part.delete();
      rethrow;
    }
    await part.rename(file.path);
    await _deleteOthers(keep: file);
    return file;
  }

  Future<void> _download(String url, File part) async {
    final response = await _client.send(http.Request('GET', Uri.parse(url)));
    if (response.statusCode != HttpStatus.ok) {
      await response.stream.drain<void>();
      throw AnimationDownloadException(response.statusCode);
    }
    // Trozo a trozo y no con addStream: si la red falla a medias, addStream
    // cierra el archivo con el error y el close() de después tapa el error
    // real (sin conexión, tiempo agotado) con un "File closed".
    final sink = part.openWrite();
    try {
      await for (final chunk in response.stream.timeout(idleTimeout)) {
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }

  // Se compara por nombre de archivo y no por ruta: al listar, Windows usa   // como separador y la ruta no coincidiría con la que se armó con /.
  Future<void> _deleteOthers({required File keep}) async {
    final keepName = keep.uri.pathSegments.last;
    await for (final entity in _directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && name != keepName && (name.endsWith('.glb') || name.endsWith('.part'))) {
        await entity.delete();
      }
    }
  }
}

/// Nombre de archivo estable para una URL (FNV-1a de 32 bits en hexadecimal).
String _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
