import 'package:flutter/material.dart';
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
  static const _reminderEnabledKey = 'reminderEnabled';
  // La hora se guarda como minutos desde las 00:00: un solo int.
  static const _reminderMinutesKey = 'reminderMinutes';
  static const _defaultReminderTime = TimeOfDay(hour: 19, minute: 0);

  bool _reduceMotion = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = _defaultReminderTime;

  /// "Reducir animaciones" de Configuración. ReduceMotionScope la suma al
  /// ajuste del sistema.
  bool get reduceMotion => _reduceMotion;

  /// "Recordatorio diario" de Configuración. Lo programa DailyReminder.
  bool get reminderEnabled => _reminderEnabled;

  /// Hora local del recordatorio diario.
  TimeOfDay get reminderTime => _reminderTime;

  // Si no se puede leer se queda con los valores por defecto: una preferencia
  // perdida no debe impedir que la app arranque.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
      _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
      final minutes = prefs.getInt(_reminderMinutesKey);
      if (minutes != null) _reminderTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    } catch (e) {
      debugPrint('AppPreferences load error: $e');
    }
  }

  // Los setters avisan antes de guardar para que el cambio se vea al instante.
  Future<void> setReduceMotion(bool value) async {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    notifyListeners();
    await _save((prefs) => prefs.setBool(_reduceMotionKey, value));
  }

  Future<void> setReminderEnabled(bool value) async {
    if (value == _reminderEnabled) return;
    _reminderEnabled = value;
    notifyListeners();
    await _save((prefs) => prefs.setBool(_reminderEnabledKey, value));
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    if (time == _reminderTime) return;
    _reminderTime = time;
    notifyListeners();
    await _save((prefs) => prefs.setInt(_reminderMinutesKey, time.hour * 60 + time.minute));
  }

  // Si no se puede guardar, el valor vale igual hasta cerrar la app.
  Future<void> _save(Future<bool> Function(SharedPreferences prefs) write) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } catch (e) {
      debugPrint('AppPreferences save error: $e');
    }
  }
}
