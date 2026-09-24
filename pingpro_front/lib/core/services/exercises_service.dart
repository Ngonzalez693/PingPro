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
import 'package:pingpro_front/core/services/api_errors.dart';
import 'package:pingpro_front/core/services/api_paths.dart';
import 'package:pingpro_front/core/services/api_responses.dart';
import 'package:pingpro_front/core/services/completion_body.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
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

  /// Crea el ejercicio y devuelve su id. Según `draft.scope` va a
  /// POST /api/exercises/me (privado del usuario) o a POST /api/exercises
  /// (catálogo, solo admin). El dueño lo pone el backend a partir del token.
  ///
  /// Si falla, la excepción lleva el mensaje del backend (p. ej. el de Joi
  /// cuando un campo no es válido, o el 403 si no es admin) para enseñarlo.
  Future<String> create(ExerciseDraft draft) async {
    final r = await http.post(
      _u(createPathFor('exercises', draft.scope)),
      headers: await _jsonHeaders(withAuth: true),
      body: jsonEncode(draft.toCreateJson()),
    );
    if (r.statusCode != 201) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo crear el ejercicio'));
    }
    final id = parseCreatedId(jsonDecode(r.body));
    if (id == null) {
      throw Exception('El servidor no devolvió el id del ejercicio creado');
    }
    return id;
  }

  /// PUT: sustituye el ejercicio `draft.editingId` entero (datos y secuencia).
  /// Lo propio va por /me; el catálogo, por la raíz (solo admins).
  Future<void> update(ExerciseDraft draft) async {
    final id = draft.editingId;
    if (id == null) throw StateError('update() necesita un borrador de edición');
    final r = await http.put(
      _u(itemPathFor('exercises', id, own: draft.scope == ContentScope.own)),
      headers: await _jsonHeaders(withAuth: true),
      body: jsonEncode(draft.toCreateJson()),
    );
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo guardar el ejercicio'));
    }
  }

  /// DELETE: el backend lo marca como borrado; deja de verse y sale de los
  /// entrenamientos que lo usaban.
  Future<void> delete(String id, {required bool own}) async {
    final r = await http.delete(
      _u(itemPathFor('exercises', id, own: own)),
      headers: await _jsonHeaders(withAuth: true),
    );
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo eliminar el ejercicio'));
    }
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
  Future<void> setCompleted({required String id, required bool completed, int? session}) async {
    final r = await http.post(
      _u('/api/exercises/$id/completed'),
      headers: await _jsonHeaders(withAuth: true),
      body: jsonEncode(completionBody(completed, session)),
    );
    if (r.statusCode != 200) {
      throw Exception('Error al actualizar completed: ${r.body}');
    }
  }
}
