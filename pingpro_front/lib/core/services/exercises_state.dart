import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pingpro_front/core/services/safe_notify.dart';
import 'package:pingpro_front/core/local_completion_events.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/core/services/stats_state.dart';

/// Store global para ejercicios con estado por usuario (favoritos / completados).
/// - Carga idempotente (no vuelve a cargar si ya lo hizo a menos que uses force).
/// - UI optimista al cambiar favorito y completado.
/// - Persistencia: los datos se obtienen del backend ya enriquecidos con `userState`.
///
/// Es la fuente de verdad de los ejercicios en toda la app. El proyecto no usa
/// Provider ni Riverpod: es un singleton (`ExercisesState.instance`) que extiende
/// ChangeNotifier, y las pantallas se suscriben con
/// `AnimatedBuilder(animation: ExercisesState.instance, ...)`.
///
/// Consecuencia práctica: varias pantallas comparten la misma lista en memoria,
/// así que marcar un ejercicio como favorito en Home se refleja al instante en
/// Ejercicios y en Perfil sin volver a pedir nada al servidor.
///
/// Al ser singleton, el estado sobreviviría al cierre de sesión: por eso
/// AuthWrapper llama a `reset()` cuando cambia el uid, o el siguiente usuario
/// vería los datos del anterior.
class ExercisesState extends ChangeNotifier with SafeNotify {
  ExercisesState._(this._service, this._stats);

  /// Con un servicio falso y un StatsState propio, para probar el store sin
  /// red ni singletons.
  @visibleForTesting
  ExercisesState.forTest({required ExercisesService service, required StatsState stats})
      : this._(service, stats);

  static final ExercisesState instance = ExercisesState._(ExercisesService(), StatsState.instance);

  final ExercisesService _service;
  final StatsState _stats;

  bool _isLoading = false;
  bool _loadedOnce = false;
  String? _error;

  // Indexado por id, no lista: getById() es O(1) y lo usan mucho la pantalla de
  // detalle y la de entrenamiento (que resuelve exerciseIds uno por uno).
  final Map<String, ExerciseModel> _byId = {};

  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;

  /// Lista ordenada alfabéticamente
  List<ExerciseModel> get all => _byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  ExerciseModel? getById(String id) => _byId[id];

  /// Carga listado + estados del usuario y los guarda en memoria.
  Future<void> load({bool force = false}) async {
    // Estas dos guardas son la razón de que casi todas las pantallas puedan
    // llamar a load() en su initState sin coste: la primera evita peticiones
    // simultáneas, la segunda evita recargar lo ya cargado.
    if (_isLoading) return;
    if (_loadedOnce && !force) return;

    _isLoading = true;
    _error = null;
    safeNotify();

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
      safeNotify();
    }
  }

  // Forzar recarga desde servidor (ignora cache en memoria).
  Future<void> refresh() => load(force: true);

  /// Crea un ejercicio (propio o de catálogo, según draft.scope) y recarga la
  /// lista para que aparezca en todas las pantallas. Sin UI optimista: el id y el dueño los asigna el
  /// backend, así que no hay nada fiable que enseñar antes de su respuesta.
  ///
  /// Si falla, relanza el error con el mensaje del backend para el SnackBar.
  Future<void> create(ExerciseDraft draft) async {
    await _service.create(draft);
    await refresh();
    unawaited(_stats.refresh());
  }

  /// Guarda los cambios de un ejercicio y recarga la lista. Sin UI optimista,
  /// como create(): la secuencia nueva la valida el backend.
  Future<void> update(ExerciseDraft draft) async {
    await _service.update(draft);
    await refresh();
    unawaited(_stats.refresh());
  }

  /// Elimina el ejercicio (por /me si es propio) y recarga la lista.
  Future<void> delete(ExerciseModel exercise) async {
    await _service.delete(exercise.id, own: exercise.isOwn);
    await refresh();
    unawaited(_stats.refresh());
  }

  /// Vacía la cache y la marca de "ya cargado".
  ///
  /// Se llama al cambiar de usuario: sin esto la guarda de `load()` daría por
  /// cargados los ejercicios del usuario anterior y el siguiente vería sus
  /// favoritos y completados.
  void reset() {
    _byId.clear();
    _loadedOnce = false;
    _error = null;
    safeNotify();
  }

  // Alterna favorito con UI optimista.
  //
  // Patrón que se repite también en setCompleted y en TrainingsState:
  //   1. se guarda el valor anterior,
  //   2. se cambia en memoria y se notifica → el icono responde al instante,
  //   3. se lanza la petición,
  //   4. si falla, rollback al valor anterior y se relanza el error para que la
  //      pantalla muestre el SnackBar.
  Future<void> toggleFavorite(String id) async {
    final ex = _byId[id];
    if (ex == null) return;

    final prev = ex.isFavorite;
    ex.isFavorite = !ex.isFavorite;
    safeNotify();

    try {
      await _service.setFavorite(id: id, isFavorite: ex.isFavorite);
    } catch (e) {
      ex.isFavorite = prev; // rollback si falla
      safeNotify();
      rethrow;
    }
  }

  /// Marca como completado con UI optimista, o deshace la última repetición
  /// (`completed` false). `session` es la sesión del día (1..3) elegida en el
  /// detalle; sin ella queda "sin sesión".
  Future<void> setCompleted(String id, bool completed, {int? session}) async {
    final ex = _byId[id];
    if (ex == null) return;
    if (!completed) return _undoLastCompletion(ex);

    final prevCompletedAt = ex.completedAt;
    ex.completedAt = DateTime.now();
    safeNotify();

    try {
      await _service.setCompleted(id: id, completed: true, session: session);
    } catch (e) {
      ex.completedAt = prevCompletedAt; // rollback si falla
      safeNotify();
      rethrow;
    }

    // El progreso por sesión sale de StatsState: se añade ya la repetición
    // confirmada para no depender de que la recarga llegue (o no falle).
    _stats.addExerciseCompletion(
      exerciseCompletionEventFor(ex, session: session, at: DateTime.now()),
    );

    // El historial vive en el servidor: sin recargar, la repetición recién
    // hecha no aparecería en las gráficas.
    unawaited(_stats.refresh());
  }

  /// Sin UI optimista sobre `completedAt`: tras deshacer, la "última vez"
  /// pasa a ser la repetición anterior, y esa solo la sabe el servidor (por
  /// eso se recarga la lista en vez de ponerlo a null).
  Future<void> _undoLastCompletion(ExerciseModel ex) async {
    await _service.setCompleted(id: ex.id, completed: false);
    _stats.removeLatestExerciseCompletion(ex.id);
    unawaited(refresh());
    unawaited(_stats.refresh());
  }

  /// Actualiza/insertar un ejercicio en memoria (por ejemplo, si vuelves del detalle con un objeto actualizado).
  void upsert(ExerciseModel e) {
    _byId[e.id] = e;
    safeNotify();
  }

  /// Helpers opcionales
  List<ExerciseModel> get favorites =>
      all.where((e) => e.isFavorite).toList();

  List<ExerciseModel> get completed =>
      all.where((e) => e.completedAt != null).toList();
}
