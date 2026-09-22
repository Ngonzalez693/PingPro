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
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String _baseUrl = dotenv.env['API_BASE_URL']!;

class Model3dCatalog {
  Model3dCatalog._();
  static final Model3dCatalog instance = Model3dCatalog._();

  static const _animationsName = 'PingPro Animations';

  String? _url;

  /// URL del .glb con todas las animaciones, o null si la fila no existe.
  Future<String?> animationsUrl() async {
    if (_url != null) return _url;
    // No se cachea un resultado null: así una fila que todavía no existe (o
    // un error de red) se reintenta en la siguiente llamada.
    final url = await _fetchAnimationsUrl();
    if (url != null) _url = url;
    return url;
  }

  Future<String?> _fetchAnimationsUrl() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.get(
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
}
