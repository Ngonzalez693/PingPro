import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/exercise_model.dart';

class ExercisesService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  // ---------- Helpers ----------
  Future<Map<String, String>> _jsonHeaders({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _u(String path) => Uri.parse('$_baseUrl$path');

  // ---------- Endpoints base ----------
  Future<List<ExerciseModel>> fetchAll() async {
    final resp = await http
        .get(_u('/api/exercises'), headers: await _jsonHeaders())
        .timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception('Error al obtener ejercicios: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final List list = data is List ? data : data['data'];
    return list.map((e) => ExerciseModel.fromJson(e)).toList();
  }

  /// Estados del usuario autenticado: { exerciseId -> { isFavorite, completedAt } }
  Future<Map<String, Map<String, dynamic>>> fetchUserStates() async {
    final resp = await http
        .get(_u('/api/exercises/me/states'), headers: await _jsonHeaders(withAuth: true))
        .timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception('Error al obtener estados de usuario: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final List list = data is List ? data : (data['data'] ?? []);
    final Map<String, Map<String, dynamic>> byId = {};
    for (final s in list) {
      byId[s['exerciseId'] as String] = {
        'isFavorite': s['isFavorite'],
        'completedAt': s['completedAt'],
      };
    }
    return byId;
  }

  /// Combina el listado “puro” con los estados del usuario.
  Future<List<ExerciseModel>> fetchAllWithUserState() async {
    final results = await Future.wait([
      fetchAll(),
      fetchUserStates(),
    ]);
    final exercises = results[0] as List<ExerciseModel>;
    final states = results[1] as Map<String, Map<String, dynamic>>;

    for (final ex in exercises) {
      final st = states[ex.id];
      if (st != null) {
        final fav = st['isFavorite'];
        if (fav is bool) ex.isFavorite = fav;

        final dt = st['completedAt'];
        ex.completedAt = (dt is String && dt.isNotEmpty) ? DateTime.tryParse(dt) : null;
      }
    }
    return exercises;
  }

  // ---------- Mutaciones ----------
  Future<void> setFavorite(String id, bool isFavorite) async {
    final resp = await http
        .post(
          _u('/api/exercises/$id/favorite'),
          headers: await _jsonHeaders(withAuth: true),
          body: jsonEncode({'isFavorite': isFavorite}),
        )
        .timeout(const Duration(seconds: 25));
    if (resp.statusCode != 200) {
      throw Exception('Error al actualizar favorito: ${resp.body}');
    }
  }

  Future<void> setCompleted(String id, bool completed) async {
    final resp = await http
        .post(
          _u('/api/exercises/$id/completed'),
          headers: await _jsonHeaders(withAuth: true),
          body: jsonEncode({'completed': completed}),
        )
        .timeout(const Duration(seconds: 25));
    if (resp.statusCode != 200) {
      throw Exception('Error al actualizar completado: ${resp.body}');
    }
  }
}
