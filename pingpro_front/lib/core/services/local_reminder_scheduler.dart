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
import 'package:timezone/data/latest.dart' as tzdata;
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
  bool _ready = false;

  // Una vez por arranque: la base de zonas horarias, la zona del teléfono y el
  // plugin. En iOS el permiso se pide al encender el interruptor, no aquí.
  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_reminder'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleDaily(TimeOfDay time) async {
    await _ensureReady();
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
    await _ensureReady();
    await _plugin.cancel(_notificationId);
  }
}
