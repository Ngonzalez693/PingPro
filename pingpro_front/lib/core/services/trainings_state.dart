import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pingpro_front/core/services/safe_notify.dart';
import 'package:pingpro_front/core/local_completion_events.dart';
import 'package:pingpro_front/models/training_draft_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/core/services/training_services.dart';
import 'package:pingpro_front/core/services/stats_state.dart';

/// Store global de entrenamientos. Gemelo de ExercisesState: singleton +
/// ChangeNotifier, carga idempotente, cache indexada por id y UI optimista con
/// rollback. Ver ExercisesState para la explicación completa del patrón.
class TrainingsState extends ChangeNotifier with SafeNotify {
  TrainingsState._(this._service, this._stats);

  /// Con un servicio falso y un StatsState propio, para probar el store sin
  /// red ni singletons.
  @visibleForTesting
  TrainingsState.forTest({required TrainingsService service, required StatsState stats})
      : this._(service, stats);

  static final TrainingsState instance = TrainingsState._(TrainingsService(), StatsState.instance);

  final TrainingsService _service;
  final StatsState _stats;

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
    _isLoading = true; _error = null; safeNotify();
    try {
      final list = await _service.fetchAllWithUserState();
      _byId
        ..clear()
        ..addEntries(list.map((t) => MapEntry(t.id, t)));
      _loadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; safeNotify();
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
    unawaited(_stats.refresh());
    return id;
  }

  /// Guarda los cambios de un entrenamiento y recarga la lista, como create().
  Future<void> update(TrainingDraft draft) async {
    await _service.update(draft);
    await refresh();
    unawaited(_stats.refresh());
  }

  /// Elimina el entrenamiento (por /me si es propio) y recarga la lista.
  Future<void> delete(TrainingModel training) async {
    await _service.delete(training.id, own: training.isOwn);
    await refresh();
    unawaited(_stats.refresh());
  }

  /// Vacía la cache y la marca de "ya cargado". Ver ExercisesState.reset().
  void reset() {
    _byId.clear();
    _loadedOnce = false;
    _error = null;
    safeNotify();
  }

  /// Marca el entrenamiento como completado (UI optimista + rollback).
  ///
  /// Quien lo llama es la pantalla de detalle, cuando detecta que todos los
  /// ejercicios del entrenamiento están hechos en la sesión. `session` es la sesión del día
  /// elegida en el detalle.
  ///
  /// Con `completed` false deshace la última finalización (al deshacer el
  /// "Hecho" que lo había completado).
  Future<void> setCompleted(String id, bool completed, {int? session}) async {
    final t = _byId[id]; if (t == null) return;
    if (!completed) return _undoLastCompletion(t);
    final prev = t.completedAt;
    t.completedAt = DateTime.now();
    safeNotify();
    try {
      await _service.setCompleted(id, true, session: session);
    } catch (_) {
      t.completedAt = prev; // revert
      safeNotify();
      rethrow;
    }

    // Como en ExercisesState: se añade ya la finalización confirmada para no
    // depender de que la recarga llegue (o no falle).
    _stats.addTrainingCompletion(
      trainingCompletionEventFor(t, session: session, at: DateTime.now()),
    );

    // El historial vive en el servidor: sin recargar, la repetición recién
    // hecha no aparecería en las gráficas.
    unawaited(_stats.refresh());
  }

  /// Como en ExercisesState: la "última vez" pasa a ser la anterior, que solo
  /// sabe el servidor, así que se recarga la lista en vez de ponerla a null.
  Future<void> _undoLastCompletion(TrainingModel t) async {
    await _service.setCompleted(t.id, false);
    _stats.removeLatestTrainingCompletion(t.id);
    unawaited(refresh());
    unawaited(_stats.refresh());
  }
}
