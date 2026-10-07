// Recordatorio diario: une la preferencia guardada (AppPreferences) con quien
// programa la notificación (ReminderScheduler). Configuración, main() y
// AuthWrapper hablan con esto, nunca con el plugin.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/core/services/local_reminder_scheduler.dart';
import 'package:pingpro_front/core/services/reminder_scheduler.dart';

enum ReminderToggle { on, off, permissionDenied }

class DailyReminder {
  DailyReminder({required this.preferences, required this.scheduler});

  static final DailyReminder instance = DailyReminder(
    preferences: AppPreferences.instance,
    scheduler: LocalReminderScheduler(),
  );

  final AppPreferences preferences;
  final ReminderScheduler scheduler;

  /// Lo llama el interruptor. Sin permiso no se enciende: la preferencia no
  /// cambia, así que el interruptor vuelve solo a apagado.
  Future<ReminderToggle> setEnabled(bool enabled) async {
    if (!enabled) {
      await scheduler.cancel();
      await preferences.setReminderEnabled(false);
      return ReminderToggle.off;
    }
    if (!await scheduler.requestPermission()) return ReminderToggle.permissionDenied;
    await scheduler.scheduleDaily(preferences.reminderTime);
    await preferences.setReminderEnabled(true);
    return ReminderToggle.on;
  }

  /// Guarda la hora y, si está encendido, lo reprograma a la nueva.
  Future<void> setTime(TimeOfDay time) async {
    await preferences.setReminderTime(time);
    if (preferences.reminderEnabled) await scheduler.scheduleDaily(time);
  }

  /// Al arrancar: lo vuelve a programar por si cambió la zona horaria o se
  /// actualizó la app. Si falla solo se registra: no debe frenar el arranque.
  Future<void> restore() async {
    if (!preferences.reminderEnabled) return;
    try {
      await scheduler.scheduleDaily(preferences.reminderTime);
    } catch (e) {
      debugPrint('DailyReminder restore error: $e');
    }
  }

  /// Al cerrar sesión o eliminar la cuenta: deja de avisar y apaga el
  /// interruptor, para que no se reprograme en el próximo arranque.
  Future<void> stop() async {
    if (!preferences.reminderEnabled) return;
    try {
      await setEnabled(false);
    } catch (e) {
      debugPrint('DailyReminder stop error: $e');
    }
  }
}
