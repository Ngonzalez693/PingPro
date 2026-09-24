import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:pingpro_front/core/services/stats_service.dart';
import 'package:pingpro_front/core/stats_series.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

typedef StatsFetcher = Future<StatsEvents> Function(DateTime from);

/// Store global del historial de estadísticas. Mismo patrón que
/// ExercisesState (singleton + ChangeNotifier, carga idempotente, reset() al
/// cambiar de usuario), con dos diferencias:
/// - el fetch se inyecta, para probar el store sin red;
/// - refresh() durante una carga no se pierde: ExercisesState y
///   TrainingsState llaman a refresh() tras cada "Hecho", y si coincide con
///   una carga en curso esa carga ya no incluye el cambio.
class StatsState extends ChangeNotifier {
  StatsState._(this._fetch);

  @visibleForTesting
  StatsState.withFetcher(StatsFetcher fetch) : this._(fetch);

  static final StatsState instance = StatsState._(StatsService().fetchEvents);

  final StatsFetcher _fetch;

  bool _isLoading = false;
  bool _loadedOnce = false;
  bool _reloadQueued = false;
  String? _error;
  StatsEvents _events = const StatsEvents();

  // Sube en cada reset(): una carga que empezó con el usuario anterior
  // compara su generación al terminar y descarta lo que trajo.
  int _generation = 0;

  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  StatsEvents get events => _events;

  Future<void> load({bool force = false}) async {
    if (_isLoading) {
      if (force) _reloadQueued = true;
      return;
    }
    if (_loadedOnce && !force) return;

    final generation = _generation;
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final events = await _fetch(statsWindowStart());
      if (generation != _generation) return;
      _events = events;
      _loadedOnce = true;
    } catch (e) {
      if (generation != _generation) return;
      _error = e.toString();
    } finally {
      // Si cambió la generación (reset() de por medio), esta carga ya es
      // ajena: no toca _isLoading ni notifica, para no pisar el estado de la
      // carga del usuario nuevo que puede estar en curso.
      if (generation == _generation) {
        _isLoading = false;
        _safeNotify();
      }
    }

    if (generation != _generation) return;

    if (_reloadQueued) {
      _reloadQueued = false;
      await load(force: true);
    }
  }

  Future<void> refresh() => load(force: true);

  /// Vacía el historial al cambiar de usuario (lo llama AuthWrapper).
  ///
  /// También libera _isLoading: si no, un load() disparado justo después
  /// (para el usuario nuevo) se creería en curso por la carga vieja y se
  /// perdería en silencio (esa carga vieja terminará descartada por la
  /// generación, sin volver a pedir nada).
  void reset() {
    _generation++;
    _isLoading = false;
    _events = const StatsEvents();
    _loadedOnce = false;
    _reloadQueued = false;
    _error = null;
    _safeNotify();
  }

  /// Notifica fuera del build: load() se llama desde initState y reset()
  /// desde el builder de AuthWrapper. Ver ExercisesState._safeNotify.
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
}
