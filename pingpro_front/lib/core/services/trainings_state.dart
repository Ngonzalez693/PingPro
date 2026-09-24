import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:pingpro_front/models/training_draft_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/core/services/training_services.dart';
import 'package:pingpro_front/core/services/stats_state.dart';

/// Store global de entrenamientos. Gemelo de ExercisesState: singleton +
/// ChangeNotifier, carga idempotente, cache indexada por id y UI optimista con
/// rollback. Ver ExercisesState para la explicación completa del patrón.
///
/// Una diferencia: aquí se usa notifyListeners() directo en vez de un
/// _safeNotify(). Funciona porque load() se dispara tras el primer await, pero
/// es más frágil que en ExercisesState; valdría la pena unificar los dos stores.
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

  /// Crea un entrenamiento (propio o de catálogo, según draft.scope), recarga la
  /// lista para que aparezca en todas las pantallas y devuelve su id. Sin UI
  /// optimista, como en ExercisesState.create: el id y el dueño los asigna el
  /// backend.
  Future<String> create(TrainingDraft draft) async {
    final id = await _service.create(draft);
    await refresh();
    unawaited(StatsState.instance.refresh());
    return id;
  }

  /// Guarda los cambios de un entrenamiento y recarga la lista, como create().
  Future<void> update(TrainingDraft draft) async {
    await _service.update(draft);
    await refresh();
    unawaited(StatsState.instance.refresh());
  }

  /// Elimina el entrenamiento (por /me si es propio) y recarga la lista.
  Future<void> delete(TrainingModel training) async {
    await _service.delete(training.id, own: training.isOwn);
    await refresh();
    unawaited(StatsState.instance.refresh());
  }

  /// Vacía la cache y la marca de "ya cargado". Ver ExercisesState.reset().
  void reset() {
    _byId.clear();
    _loadedOnce = false;
    _error = null;
    _safeNotify();
  }

  /// Notifica fuera del build. A diferencia del resto de métodos, reset() lo
  /// llama AuthWrapper desde su builder, donde un notifyListeners() directo
  /// rompería con "setState() called during build".
  void _safeNotify() {
    if (!hasListeners) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  /// Marca el entrenamiento como completado (UI optimista + rollback).
  ///
  /// Quien lo llama es la pantalla de detalle, cuando detecta que todos los
  /// ejercicios del entrenamiento están hechos.
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

    // El historial vive en el servidor: sin recargar, la repetición recién
    // hecha no aparecería en las gráficas.
    unawaited(StatsState.instance.refresh());
  }
}
