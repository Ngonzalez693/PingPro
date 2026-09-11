// Cliente HTTP de ejercicios. Capa más baja del lado de datos: solo habla con
// la API y devuelve modelos. Quien guarda estado es ExercisesState.
//
// El catálogo y el progreso del usuario vienen de endpoints separados
// (/api/exercises y /api/exercises/me/states) y se juntan aquí en
// fetchAllMergedWithUserState(), que es lo que consume el store.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/exercise_model.dart';

/// Estado de un ejercicio para el usuario actual.
typedef ExerciseUserState = ({bool isFavorite, DateTime? completedAt});

/// Convierte la respuesta de GET /api/exercises/me/states en un índice por id
/// de ejercicio.
///
/// Contrato del backend:
///   { "success": true,
///     "data": [ { "exerciseId": "...", "isFavorite": true,
///                 "completedAt": "2026-09-11T17:49:11.698Z" } ] }
/// `completedAt` es texto ISO 8601 o null; `isFavorite` puede faltar.
///
/// Está separada de la petición HTTP para poder probarla sola. La versión
/// anterior aceptaba cinco formatos que el backend nunca enviaba y descartaba
/// el único que sí enviaba, así que favoritos y completados no se cargaban.
Map<String, ExerciseUserState> parseExerciseStates(Object? body) {
  final data = body is Map ? body['data'] : null;
  if (data is! List) return {};

  final byId = <String, ExerciseUserState>{};
  for (final item in data) {
    if (item is! Map) continue;
    final id = item['exerciseId'];
    if (id is! String || id.isEmpty) continue;
    final completedAt = item['completedAt'];
    byId[id] = (
      isFavorite: item['isFavorite'] == true,
      completedAt: completedAt is String ? DateTime.tryParse(completedAt) : null,
    );
  }
  return byId;
}

class ExercisesService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  Uri _u(String p) => Uri.parse('$_baseUrl$p');

  Future<Map<String, String>> _jsonHeaders({bool withAuth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final u = FirebaseAuth.instance.currentUser;
      final token = await u?.getIdToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // GET /api/exercises (sin estado de usuario)
  Future<List<ExerciseModel>> fetchAll() async {
    final r = await http.get(_u('/api/exercises'), headers: await _jsonHeaders(withAuth: true));
    if (r.statusCode != 200) {
      throw Exception('Error al obtener ejercicios: ${r.body}');
    }
    final data = jsonDecode(r.body);
    final list = (data is List) ? data : (data['data'] as List);
    return list.map<ExerciseModel>((e) => ExerciseModel.fromJson(e)).toList();
  }

  /// GET /api/exercises/me/states (auth): favoritos y completados del usuario.
  Future<Map<String, ExerciseUserState>> fetchMyStates() async {
    final r = await http.get(
      _u('/api/exercises/me/states'),
      headers: await _jsonHeaders(withAuth: true),
    );
    if (r.statusCode != 200) {
      throw Exception('Error al obtener estados del usuario: ${r.body}');
    }
    return parseExerciseStates(jsonDecode(r.body));
  }

  /// GET ejercicios + GET estados y MERGE a ExerciseModel
  ///
  /// Es el único método que usa ExercisesState: entrega los ejercicios ya
  /// marcados con favorito y completado del usuario actual.
  Future<List<ExerciseModel>> fetchAllMergedWithUserState() async {
    // Las dos peticiones son independientes → en paralelo, no encadenadas.
    final results = await Future.wait([
      fetchAll(),
      fetchMyStates(),
    ]);
    final exercises = results[0] as List<ExerciseModel>;
    final states = results[1] as Map<String, ExerciseUserState>;

    for (final ex in exercises) {
      final st = states[ex.id];
      ex.isFavorite = st?.isFavorite ?? false;
      ex.completedAt = st?.completedAt;
    }
    return exercises;
  }

  /// POST /api/exercises/:id/favorite
  Future<void> setFavorite({required String id, required bool isFavorite}) async {
    final r = await http.post(
      _u('/api/exercises/$id/favorite'),
      headers: await _jsonHeaders(withAuth: true),
      body: jsonEncode({'isFavorite': isFavorite}),
    );
    if (r.statusCode != 200) {
      throw Exception('Error al actualizar favorito: ${r.body}');
    }
  }

  /// POST /api/exercises/:id/completed
  Future<void> setCompleted({required String id, required bool completed}) async {
    final r = await http.post(
      _u('/api/exercises/$id/completed'),
      headers: await _jsonHeaders(withAuth: true),
      body: jsonEncode({'completed': completed}),
    );
    if (r.statusCode != 200) {
      throw Exception('Error al actualizar completed: ${r.body}');
    }
  }
}
