// Recarga el usuario de Firebase sin dejar escapar el error. Sin conexión
// reload() falla, y la pantalla tiene que redibujarse igual con lo que ya
// tenga (AuthService ya recargó el usuario al cambiar la foto).
import 'package:flutter/foundation.dart';

Future<void> refreshUser(Future<void> Function()? reload) async {
  if (reload == null) return;
  try {
    await reload();
  } catch (e) {
    if (kDebugMode) debugPrint('No se pudo recargar el usuario: $e');
  }
}
