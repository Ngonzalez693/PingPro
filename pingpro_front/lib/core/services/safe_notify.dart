import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// notifyListeners() que se puede llamar en cualquier momento.
///
/// Los stores notifican desde sitios que corren en mitad de un build: load()
/// desde el initState de las pantallas y reset() desde el builder de
/// AuthWrapper. Ahí un notifyListeners() directo lanza "setState() called
/// during build", así que se aplaza al final del frame. Fuera del build se
/// notifica en el momento.
mixin SafeNotify on ChangeNotifier {
  @protected
  void safeNotify() {
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
