// Cliente HTTP de entrenamientos.
//
// Más simple que ExercisesService porque aquí el cruce con el progreso lo hace
// el backend: /api/trainings/me/list ya devuelve el catálogo con completedAt
// incluido, así que no hay merge en el cliente.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/services/api_errors.dart';
import 'package:pingpro_front/core/services/api_paths.dart';
import 'package:pingpro_front/core/services/api_responses.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/training_draft_model.dart';
import 'package:pingpro_front/models/training_model.dart';

class TrainingsService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, String>> _jsonHeaders({bool withAuth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) h['Authorization'] = 'Bearer ${await u.getIdToken()}';
    }
    return h;
  }

  Uri _u(String p) => Uri.parse('$_baseUrl$p');

  // Listado “puro”
  Future<List<TrainingModel>> fetchAll() async {
    final r = await http
        .get(_u('/api/trainings'), headers: await _jsonHeaders(withAuth: true))
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception('Error al obtener trainings: ${r.body}');
    }
    final data = jsonDecode(r.body);
    // El backend envuelve en { success, data }, pero se acepta también el array
    // pelado por si el endpoint cambia (Model3DController ya responde así).
    final List list = data is List ? data : data['data'];
    return list.map((e) => TrainingModel.fromJson(e)).toList();
  }

  // Listado enriquecido con estado del usuario (endpoint: GET /api/trainings/me/list)
  // Es el que usa TrainingsState; fetchAll() queda para usos sin sesión.
  Future<List<TrainingModel>> fetchAllWithUserState() async {
    final r = await http
        .get(_u('/api/trainings/me/list'), headers: await _jsonHeaders(withAuth: true))
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception('Error al obtener trainings del usuario: ${r.body}');
    }
    final data = jsonDecode(r.body);
    final List list = data is List ? data : data['data'];
    return list.map((e) => TrainingModel.fromJson(e)).toList();
  }

  /// Crea el entrenamiento y devuelve su id. Según `draft.scope` va a
  /// POST /api/trainings/me (privado) o a POST /api/trainings (catálogo, solo
  /// admin). El backend comprueba que todos los ejercicios sean visibles para
  /// ese destino: uno del catálogo solo puede usar ejercicios del catálogo.
  Future<String> create(TrainingDraft draft) async {
    final r = await http
        .post(
          _u(createPathFor('trainings', draft.scope)),
          headers: await _jsonHeaders(withAuth: true),
          body: jsonEncode(draft.toCreateJson()),
        )
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 201) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo crear el entrenamiento'));
    }
    final id = parseCreatedId(jsonDecode(r.body));
    if (id == null) {
      throw Exception('El servidor no devolvió el id del entrenamiento creado');
    }
    return id;
  }

  /// PUT: sustituye el entrenamiento `draft.editingId` entero (datos y
  /// ejercicios). Lo propio va por /me; el catálogo, por la raíz (solo admins).
  Future<void> update(TrainingDraft draft) async {
    final id = draft.editingId;
    if (id == null) throw StateError('update() necesita un borrador de edición');
    final r = await http
        .put(
          _u(itemPathFor('trainings', id, own: draft.scope == ContentScope.own)),
          headers: await _jsonHeaders(withAuth: true),
          body: jsonEncode(draft.toCreateJson()),
        )
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo guardar el entrenamiento'));
    }
  }

  /// DELETE: el backend lo marca como borrado. Sus ejercicios no se tocan.
  Future<void> delete(String id, {required bool own}) async {
    final r = await http
        .delete(_u(itemPathFor('trainings', id, own: own)), headers: await _jsonHeaders(withAuth: true))
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudo eliminar el entrenamiento'));
    }
  }

  // Marcar/unmarcar como completado para el usuario
  Future<void> setCompleted(String id, bool completed) async {
    final r = await http
        .post(
          _u('/api/trainings/$id/completed'),
          headers: await _jsonHeaders(withAuth: true),
          body: jsonEncode({'completed': completed}),
        )
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception('Error al actualizar training: ${r.body}');
    }
  }
}
