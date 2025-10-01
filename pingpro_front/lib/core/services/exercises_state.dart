import 'package:flutter/foundation.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';

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

  List<ExerciseModel> get all => _byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  ExerciseModel? getById(String id) => _byId[id];

  /// Carga listado + estados del usuario y los mergea en memoria.
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_loadedOnce && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.fetchAllWithUserState();
      _byId
        ..clear()
        ..addEntries(list.map((e) => MapEntry(e.id, e)));
      _loadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna favorito con UI optimista.
  Future<void> toggleFavorite(String id) async {
    final ex = _byId[id];
    if (ex == null) return;
    final prev = ex.isFavorite;
    ex.isFavorite = !ex.isFavorite;
    notifyListeners();

    try {
      await _service.setFavorite(id, ex.isFavorite);
    } catch (_) {
      ex.isFavorite = prev; // revertir si falla
      notifyListeners();
      rethrow;
    }
  }

  /// Set completed/uncompleted (solo desde detalle).
  Future<void> setCompleted(String id, bool completed) async {
    final ex = _byId[id];
    if (ex == null) return;
    final prev = ex.completedAt;
    ex.completedAt = completed ? DateTime.now() : null;
    notifyListeners();

    try {
      await _service.setCompleted(id, completed);
    } catch (_) {
      ex.completedAt = prev; // revertir si falla
      notifyListeners();
      rethrow;
    }
  }
}
