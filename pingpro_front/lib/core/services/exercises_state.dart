import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart'; // 👈 para SchedulerBinding
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';

/// Store global para ejercicios con estado por usuario (favoritos / completados).
/// - Carga idempotente (no vuelve a cargar si ya lo hizo a menos que uses force).
/// - UI optimista al cambiar favorito y completado.
/// - Persistencia: los datos se obtienen del backend ya enriquecidos con `userState`.
class ExercisesState extends ChangeNotifier {
  ExercisesState._();
  static final ExercisesState instance = ExercisesState._();

  final _service = ExercisesService();

  bool _isLoading = false;
  bool _loadedOnce = false;
  String? _error;

  final Map<String, ExerciseModel> _byId = {};

  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;

  /// Lista ordenada alfabéticamente
  List<ExerciseModel> get all => _byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  ExerciseModel? getById(String id) => _byId[id];

  /// Notifica de forma segura: si estamos en mitad de un build, pospone la notificación.
  void _safeNotify() {
    if (!hasListeners) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      // Es seguro notificar ahora
      notifyListeners();
    } else {
      // Posponer al siguiente frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  /// Carga listado + estados del usuario y los guarda en memoria.
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_loadedOnce && !force) return;

    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final list = await _service.fetchAllMergedWithUserState();
      _byId
        ..clear()
        ..addEntries(list.map((e) => MapEntry(e.id, e)));
      _loadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // Forzar recarga desde servidor (ignora cache en memoria).
  Future<void> refresh() => load(force: true);

  // Alterna favorito con UI optimista.
  Future<void> toggleFavorite(String id) async {
    final ex = _byId[id];
    if (ex == null) return;

    final prev = ex.isFavorite;
    ex.isFavorite = !ex.isFavorite;
    _safeNotify();

    try {
      await _service.setFavorite(id: id, isFavorite: ex.isFavorite);
    } catch (e) {
      ex.isFavorite = prev; // rollback si falla
      _safeNotify();
      rethrow;
    }
  }

  /// Marca/desmarca como completado con UI optimista.
  /// En backend debe persistir `completedAt` (o `lastCompletedAt`) por usuario.
  Future<void> setCompleted(String id, bool completed) async {
    final ex = _byId[id];
    if (ex == null) return;

    final prevCompletedAt = ex.completedAt;
    ex.completedAt = completed ? DateTime.now() : null;
    _safeNotify();

    try {
      await _service.setCompleted(id: id, completed: completed);
    } catch (e) {
      ex.completedAt = prevCompletedAt; // rollback si falla
      _safeNotify();
      rethrow;
    }
  }

  /// Actualiza/insertar un ejercicio en memoria (por ejemplo, si vuelves del detalle con un objeto actualizado).
  void upsert(ExerciseModel e) {
    _byId[e.id] = e;
    _safeNotify();
  }

  /// Helpers opcionales
  List<ExerciseModel> get favorites =>
      all.where((e) => e.isFavorite).toList();

  List<ExerciseModel> get completed =>
      all.where((e) => e.completedAt != null).toList();
}
