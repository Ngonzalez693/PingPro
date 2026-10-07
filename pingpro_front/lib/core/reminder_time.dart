// Hora del recordatorio diario: cuándo toca la próxima vez y cómo se muestra.
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// Próxima vez que toca: hoy a esa hora si todavía no pasó, si no mañana.
/// Con DateTimeComponents.time el plugin la repite después cada día.
tz.TZDateTime nextDailyAt(TimeOfDay time, tz.TZDateTime now) {
  final today = tz.TZDateTime(now.location, now.year, now.month, now.day, time.hour, time.minute);
  if (today.isAfter(now)) return today;
  return tz.TZDateTime(now.location, now.year, now.month, now.day + 1, time.hour, time.minute);
}

/// Siempre 24 h, igual que el selector de hora de Configuración.
String formatReminderTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
