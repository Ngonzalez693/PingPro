import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Preferencias guardadas en el teléfono (shared_preferences).
//
// Son por dispositivo y no por cuenta: no pasan por el backend ni se vacían al
// cerrar sesión, a diferencia de los stores. Se cargan en main() antes de
// runApp para que la primera pantalla ya las respete.
class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  @visibleForTesting
  AppPreferences.forTesting();

  static final AppPreferences instance = AppPreferences._();

  static const _reduceMotionKey = 'reduceMotion';

  bool _reduceMotion = false;

  /// "Reducir animaciones" de Configuración. ReduceMotionScope la suma al
  /// ajuste del sistema.
  bool get reduceMotion => _reduceMotion;

  // Si no se puede leer se queda con los valores por defecto: una preferencia
  // perdida no debe impedir que la app arranque.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    } catch (e) {
      debugPrint('AppPreferences load error: $e');
    }
  }

  // Avisa antes de guardar para que el cambio se vea al instante. Si no se
  // puede guardar, vale igual hasta cerrar la app.
  Future<void> setReduceMotion(bool value) async {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reduceMotionKey, value);
    } catch (e) {
      debugPrint('AppPreferences save error: $e');
    }
  }
}
