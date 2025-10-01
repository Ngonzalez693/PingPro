import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/exercise_model.dart';

class ExercisesService {
  final _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<List<ExerciseModel>> fetchAll() async {
    final uri = Uri.parse('$_baseUrl/api/exercises');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Error al cargar ejercicios (${response.statusCode})');
    }

    // parsear el JSON completo como Map
    final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
    // extraer lista desde la clave "data"
    final List<dynamic> list = json['data'] as List<dynamic>;

    return list
        .map((item) => ExerciseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No autenticado');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('No se pudo obtener el token de autenticación');
    return idToken;
  }

  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    final idToken = await _getIdToken();
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/api/exercises/$id/favorite'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'isFavorite': isFavorite}),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('Error al actualizar favorito: ${resp.body}');
    }
  }

  Future<void> setCompleted({
    required String id,
    required bool completed,
  }) async {
    final idToken = await _getIdToken();
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/api/exercises/$id/completed'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'completed': completed}),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('Error al actualizar completado: ${resp.body}');
    }
  }
}
