import 'package:flutter/foundation.dart';
import 'package:pingpro_front/core/session_progress.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

/// Sesión del día (1..3) elegida en el selector, compartida por el detalle de
/// ejercicio y el de entrenamiento.
///
/// Solo guarda la elección explícita, y solo vale el día en que se hizo. Sin
/// ella manda defaultSession(), que sale del historial del servidor: así la
/// sesión en curso sobrevive a reiniciar la app sin guardar nada en el
/// teléfono.
class CurrentSession extends ChangeNotifier {
  CurrentSession._(this._clock);

  @visibleForTesting
  CurrentSession.withClock(DateTime Function() clock) : this._(clock);

  static final CurrentSession instance = CurrentSession._(DateTime.now);

  final DateTime Function() _clock;
  int? _chosen;
  DateTime? _chosenOn;

  int sessionFor(StatsEvents events) {
    final now = _clock();
    final chosen = _chosen;
    final chosenOn = _chosenOn;
    if (chosen != null && chosenOn != null && isSameDay(chosenOn, now)) return chosen;
    return defaultSession(events, now: now);
  }

  void choose(int session) {
    if (!sessionNumbers.contains(session)) {
      throw ArgumentError.value(session, 'session', 'debe ser 1, 2 o 3');
    }
    _chosen = session;
    _chosenOn = _clock();
    notifyListeners();
  }

  /// Olvida la elección al cambiar de usuario. No notifica: lo llama
  /// AuthWrapper en mitad de un build, y al cambiar de usuario las pantallas
  /// que escuchan se construyen de nuevo.
  void reset() {
    _chosen = null;
    _chosenOn = null;
  }
}
