// Dónde está el .glb con todas las animaciones.
//
// La URL vive en la fila 'PingPro Animations' de models_3d y no en la app, así
// que resubir el archivo (p. ej. al rehacer un clip) no obliga a publicar otra
// versión.
//
// Singleton con carga perezosa: la primera vez que se abre un ejercicio pide
// GET /api/model3d y guarda la URL para el resto de la sesión. Si la fila no
// existe o la petición falla no se guarda nada y la siguiente llamada vuelve
// a intentarlo.
//
// Además recuerda la última URL en el teléfono: el archivo ya está guardado
// (AnimationFileCache), así que sin red se sigue pudiendo abrir un ejercicio
// con la última URL conocida en vez de quedarse sin animación.
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pingpro_front/core/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String _baseUrl = dotenv.env['API_BASE_URL']!;

const _animationsName = 'PingPro Animations';
const _savedUrlKey = 'animationsUrl';

class Model3dCatalog {
  final Future<String?> Function() _fetch;

  Model3dCatalog._(this._fetch);
  static final Model3dCatalog instance = Model3dCatalog._(_fetchAnimationsUrl);

  @visibleForTesting
  Model3dCatalog.withFetcher(Future<String?> Function() fetch) : _fetch = fetch;

  String? _url;

  /// URL del .glb con todas las animaciones, o null si la fila no existe. Sin
  /// red devuelve la última recordada; si no hay ninguna, relanza el error.
  Future<String?> animationsUrl() async {
    if (_url != null) return _url;
    // No se cachea un resultado null: así una fila que todavía no existe (o
    // un error de red) se reintenta en la siguiente llamada.
    final String? url;
    try {
      url = await _fetch();
    } on Object catch (e) {
      final saved = (await SharedPreferences.getInstance()).getString(_savedUrlKey);
      if (saved == null) rethrow;
      debugPrint('Model3dCatalog: sin respuesta ($e), uso la última URL recordada');
      return saved;
    }
    if (url != null) {
      _url = url;
      await _remember(url);
    }
    return url;
  }

  // Recordarla es una mejora: si falla, la URL de esta sesión sigue valiendo.
  Future<void> _remember(String url) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_savedUrlKey, url);
    } on Exception catch (e) {
      debugPrint('Model3dCatalog: no se pudo recordar la URL: $e');
    }
  }
}

Future<String?> _fetchAnimationsUrl() async {
  final user = FirebaseAuth.instance.currentUser;
  final token = user == null ? null : await withRequestTimeout(user.getIdToken());
  final response = await apiClient.get(
    Uri.parse('$_baseUrl/api/model3d'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode != 200) {
    throw Exception('Model3D list failed: ${response.statusCode} ${response.body}');
  }
  // Model3DController es el único controller del backend que responde un
  // array pelado, sin el envoltorio { success, data }.
  final rows = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  final match = rows.where((row) => row['name'] == _animationsName);
  return match.isEmpty ? null : match.first['url'] as String;
}
