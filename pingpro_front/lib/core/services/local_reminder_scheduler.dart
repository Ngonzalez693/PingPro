// Recordatorio diario con flutter_local_notifications, sin servidor.
//
// inexactAllowWhileIdle: puede llegar unos minutos tarde, pero evita el
// permiso de alarmas exactas, que Google Play restringe. El receptor de
// arranque del AndroidManifest lo reprograma tras reiniciar el teléfono.
// Tocar la notificación abre la app (comportamiento por defecto del plugin).
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pingpro_front/core/reminder_time.dart';
import 'package:pingpro_front/core/services/reminder_scheduler.dart';
// latest_all y no latest: la base por defecto no trae los ids heredados que
// Android sigue informando (Asia/Calcutta, America/Buenos_Aires, Europe/Kiev,
// Asia/Saigon, Asia/Katmandu, Asia/Istanbul, Etc/UTC) y getLocation fallaba.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderScheduler implements ReminderScheduler {
  static const _notificationId = 0;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Recordatorio diario',
      channelDescription: 'Aviso diario para entrenar',
    ),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _pluginReady;
  Future<void>? _zoneReady;

  // Se guarda el Future para que las primeras llamadas concurrentes compartan
  // la misma inicialización. Si falla se descarta, para que una llamada
  // posterior pueda reintentar en vez de quedarse con el error cacheado.
  Future<void> _once(Future<void> Function() init, void Function() reset) async {
    try {
      await init();
    } catch (_) {
      reset();
      rethrow;
    }
  }

  // Solo el plugin: cancelar y pedir permiso no dependen de la zona horaria.
  // Así se puede apagar el recordatorio aunque la zona no se pueda resolver.
  // En iOS el permiso se pide al encender el interruptor, no aquí.
  Future<void> _ensurePlugin() {
    return _pluginReady ??= _once(_initPlugin, () => _pluginReady = null);
  }

  Future<void> _initPlugin() async {
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_reminder'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
  }

  // La base de zonas horarias y la zona del teléfono, solo para programar.
  Future<void> _ensureZone() {
    return _zoneReady ??= _once(_initZone, () => _zoneReady = null);
  }

  Future<void> _initZone() async {
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  }

  @override
  Future<bool> requestPermission() async {
    await _ensurePlugin();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleDaily(TimeOfDay time) async {
    await _ensurePlugin();
    await _ensureZone();
    await _plugin.zonedSchedule(
      _notificationId,
      'PingPro',
      '🏓 ¿Entrenamos hoy? Tu próxima sesión te espera',
      nextDailyAt(time, tz.TZDateTime.now(tz.local)),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await _ensurePlugin();
    await _plugin.cancel(_notificationId);
  }
}
