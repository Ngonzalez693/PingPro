// Lo que el recordatorio diario necesita de las notificaciones del teléfono.
//
// Interfaz para poder probar DailyReminder con un falso, sin el plugin.
import 'package:flutter/material.dart';

abstract class ReminderScheduler {
  /// Pide permiso para notificar (Android 13+). true si quedó concedido.
  Future<bool> requestPermission();

  /// Programa el aviso diario a esa hora local; reemplaza al anterior.
  Future<void> scheduleDaily(TimeOfDay time);

  Future<void> cancel();
}
