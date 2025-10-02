import 'package:flutter/foundation.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/core/services/training_services.dart';

class TrainingsState extends ChangeNotifier {
  TrainingsState._();
  static final TrainingsState instance = TrainingsState._();

  final _service = TrainingsService();

  bool _isLoading = false;
  bool _loadedOnce = false;
  String? _error;
  final Map<String, TrainingModel> _byId = {};

  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;

  List<TrainingModel> get all => _byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  TrainingModel? getById(String id) => _byId[id];

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_loadedOnce && !force) return;
    _isLoading = true; _error = null; notifyListeners();
    try {
      final list = await _service.fetchAllWithUserState();
      _byId
        ..clear()
        ..addEntries(list.map((t) => MapEntry(t.id, t)));
      _loadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // Forzar recarga desde servidor (ignora cache en memoria).
  Future<void> refresh() => load(force: true);

  Future<void> setCompleted(String id, bool completed) async {
    final t = _byId[id]; if (t == null) return;
    final prev = t.completedAt;
    t.completedAt = completed ? DateTime.now() : null;
    notifyListeners();
    try {
      await _service.setCompleted(id, completed);
    } catch (_) {
      t.completedAt = prev; // revert
      notifyListeners();
      rethrow;
    }
  }
}
