/// Cliente HTTP de ejercicios. Capa más baja del lado de datos: solo habla con
/// la API y devuelve modelos. Quien guarda estado es ExercisesState.
///
/// El catálogo y el progreso del usuario vienen de endpoints separados
/// (/api/exercises y /api/exercises/me/states) y se juntan aquí en
/// fetchAllMergedWithUserState(), que es lo que consume el store.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/exercise_model.dart';

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
    final r = await http.get(_u('/api/exercises'), headers: await _jsonHeaders());
    if (r.statusCode != 200) {
      throw Exception('Error al obtener ejercicios: ${r.body}');
    }
    final data = jsonDecode(r.body);
    final list = (data is List) ? data : (data['data'] as List);
    return list.map<ExerciseModel>((e) => ExerciseModel.fromJson(e)).toList();
  }

  /// GET /api/exercises/me/states (auth) → { exerciseId: {isFavorite, completedAt} }
  ///
  /// DEUDA TÉCNICA: todo lo que sigue son ~100 líneas defensivas que aceptan
  /// cinco formas distintas de respuesta (array de objetos, mapa id→bool,
  /// mapa id→objeto, envoltura {data:...} y {favorites:[], completed:[]}).
  /// Se escribió así porque el contrato del endpoint nunca se fijó.
  /// El backend hoy devuelve solo la primera forma; el resto se puede borrar en
  /// cuanto se congele el contrato.
  Future<Map<String, Map<String, dynamic>>> fetchMyStates() async {
    final r = await http.get(
      _u('/api/exercises/me/states'),
      headers: await _jsonHeaders(withAuth: true),
    );
    if (r.statusCode != 200) {
      throw Exception('Error al obtener estados del usuario: ${r.body}');
    }
    final raw = jsonDecode(r.body);
    final Map<String, Map<String, dynamic>> byId = {};

    void setFav(String id, bool v) {
      final m = byId[id] ?? <String, dynamic>{};
      m['isFavorite'] = v;
      byId[id] = m;
    }

    void setCompleted(String id, dynamic value) {
      final m = byId[id] ?? <String, dynamic>{};
      // value puede ser bool, string ISO o epoch
      if (value is bool) {
        m['completedAt'] = value ? DateTime.now().toIso8601String() : null;
      } else if (value is String) {
        m['completedAt'] = value;
      } else if (value is num) {
        m['completedAt'] = DateTime.fromMillisecondsSinceEpoch(value.toInt())
            .toIso8601String();
      } else {
        m['completedAt'] = null;
      }
      byId[id] = m;
    }

    // ---- 1) Si es array de objetos [{exerciseId, isFavorite, completedAt}] ----
    if (raw is List) {
      for (final s in raw) {
        if (s is Map) {
          final id = '${s['exerciseId'] ?? s['id'] ?? ''}';
          if (id.isEmpty) continue;
          if (s.containsKey('isFavorite')) setFav(id, s['isFavorite'] == true);
          if (s.containsKey('favorite')) setFav(id, s['favorite'] == true);
          if (s.containsKey('completedAt')) setCompleted(id, s['completedAt']);
          if (s.containsKey('completed')) {
            final v = s['completed'];
            if (v is bool) {
              setCompleted(id, v ? DateTime.now().toIso8601String() : null);
            } else {
              setCompleted(id, v);
            }
          }
        }
      }
      return byId;
    }

    if (raw is! Map) return byId;

    // Si viene envuelto en { data: ... }
    final data = (raw['data'] is Map || raw['data'] is List) ? raw['data'] : raw;

    // ---- 2) Mapa de id -> objeto o id -> bool ----
    if (data is Map) {
      bool hasComposite = false;

      // a) composite: { favorites: [...]/map, completed: [...]/map }
      if (data.containsKey('favorites') || data.containsKey('completed')) {
        hasComposite = true;

        // favorites puede ser lista de ids o mapa id->bool
        final favs = data['favorites'];
        if (favs is List) {
          for (final id in favs) {
            setFav('$id', true);
          }
        } else if (favs is Map) {
          favs.forEach((k, v) => setFav('$k', v == true));
        }

        // completed puede ser lista de ids o mapa id->timestamp/bool
        final comp = data['completed'];
        if (comp is List) {
          for (final id in comp) {
            setCompleted('$id', true);
          }
        } else if (comp is Map) {
          comp.forEach((k, v) => setCompleted('$k', v));
        }
      }

      // b) simple: { "<id>": {isFavorite, completedAt} }  ó { "<id>": true|false }
      if (!hasComposite) {
        data.forEach((k, v) {
          final id = '$k';
          if (v is bool) {
            // tu caso: true/false => favorito
            setFav(id, v);
          } else if (v is Map) {
            if (v.containsKey('isFavorite')) setFav(id, v['isFavorite'] == true);
            if (v.containsKey('favorite')) setFav(id, v['favorite'] == true);
            if (v.containsKey('completedAt')) setCompleted(id, v['completedAt']);
            if (v.containsKey('completed')) setCompleted(id, v['completed']);
          }
        });
      }
    }

    return byId;
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
    final states = results[1] as Map<String, Map<String, dynamic>>;

    for (final ex in exercises) {
      final st = states[ex.id];
      if (st != null) {
        ex.isFavorite = (st['isFavorite'] ?? false) as bool;
        final completedAt = st['completedAt'];
        if (completedAt is String) {
          ex.completedAt = DateTime.tryParse(completedAt);
        } else if (completedAt is num) {
          ex.completedAt = DateTime.fromMillisecondsSinceEpoch(completedAt.toInt());
        } else {
          ex.completedAt = null;
        }
      } else {
        ex.isFavorite = false;
        ex.completedAt = null;
      }
    }
    if (kDebugMode) {
      // debug rápido para ver cuántos estados entraron
      // print('Merged exercises: ${exercises.length} (states: ${states.length})');
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
