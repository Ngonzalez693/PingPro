import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart'; // 👈 para SchedulerBinding
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';

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
class ExercisesState extends ChangeNotifier {
  ExercisesState._();
  static final ExercisesState instance = ExercisesState._();

  final _service = ExercisesService();

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

  /// Notifica de forma segura: si estamos en mitad de un build, pospone la notificación.
  ///
  /// Hace falta porque varias pantallas llaman a load() desde initState, que
  /// corre durante el build. Un notifyListeners() en ese momento lanza
  /// "setState() called during build"; aquí se aplaza al siguiente frame.
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
    // Estas dos guardas son la razón de que casi todas las pantallas puedan
    // llamar a load() en su initState sin coste: la primera evita peticiones
    // simultáneas, la segunda evita recargar lo ya cargado.
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

  /// Crea un ejercicio (propio o de catálogo, según draft.scope) y recarga la
  /// lista para que aparezca en todas las pantallas. Sin UI optimista: el id y el dueño los asigna el
  /// backend, así que no hay nada fiable que enseñar antes de su respuesta.
  ///
  /// Si falla, relanza el error con el mensaje del backend para el SnackBar.
  Future<void> create(ExerciseDraft draft) async {
    await _service.create(draft);
    await refresh();
  }

  /// Guarda los cambios de un ejercicio y recarga la lista. Sin UI optimista,
  /// como create(): la secuencia nueva la valida el backend.
  Future<void> update(ExerciseDraft draft) async {
    await _service.update(draft);
    await refresh();
  }

  /// Elimina el ejercicio (por /me si es propio) y recarga la lista.
  Future<void> delete(ExerciseModel exercise) async {
    await _service.delete(exercise.id, own: exercise.isOwn);
    await refresh();
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
    _safeNotify();
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
