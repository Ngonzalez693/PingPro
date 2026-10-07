import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/core/services/daily_reminder.dart';
import 'package:pingpro_front/core/services/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScheduler implements ReminderScheduler {
  bool grantPermission = true;
  bool failToSchedule = false;
  final List<TimeOfDay> scheduled = [];
  int cancels = 0;

  @override
  Future<bool> requestPermission() async => grantPermission;

  @override
  Future<void> scheduleDaily(TimeOfDay time) async {
    if (failToSchedule) throw StateError('plugin roto');
    scheduled.add(time);
  }

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  late FakeScheduler scheduler;

  Future<DailyReminder> reminderWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = AppPreferences.forTesting();
    await prefs.load();
    scheduler = FakeScheduler();
    return DailyReminder(preferences: prefs, scheduler: scheduler);
  }

  test('encenderlo con permiso lo programa a la hora guardada y lo recuerda', () async {
    final reminder = await reminderWith({'reminderMinutes': 8 * 60});

    final result = await reminder.setEnabled(true);

    expect(result, ReminderToggle.on);
    expect(scheduler.scheduled, [const TimeOfDay(hour: 8, minute: 0)]);
    expect(reminder.preferences.reminderEnabled, isTrue);
  });

  test('sin permiso no se enciende ni programa nada', () async {
    final reminder = await reminderWith({});
    scheduler.grantPermission = false;

    final result = await reminder.setEnabled(true);

    expect(result, ReminderToggle.permissionDenied);
    expect(scheduler.scheduled, isEmpty);
    expect(reminder.preferences.reminderEnabled, isFalse);
  });

  test('apagarlo cancela y lo recuerda', () async {
    final reminder = await reminderWith({'reminderEnabled': true});

    final result = await reminder.setEnabled(false);

    expect(result, ReminderToggle.off);
    expect(scheduler.cancels, 1);
    expect(reminder.preferences.reminderEnabled, isFalse);
  });

  test('cambiar la hora encendido lo reprograma; apagado solo la guarda', () async {
    final on = await reminderWith({'reminderEnabled': true});
    await on.setTime(const TimeOfDay(hour: 9, minute: 30));
    expect(scheduler.scheduled, [const TimeOfDay(hour: 9, minute: 30)]);

    final off = await reminderWith({});
    await off.setTime(const TimeOfDay(hour: 9, minute: 30));
    expect(scheduler.scheduled, isEmpty);
    expect(off.preferences.reminderTime, const TimeOfDay(hour: 9, minute: 30));
  });

  test('al arrancar lo reprograma solo si estaba encendido', () async {
    final on = await reminderWith({'reminderEnabled': true});
    await on.restore();
    expect(scheduler.scheduled, [const TimeOfDay(hour: 19, minute: 0)]);

    final off = await reminderWith({});
    await off.restore();
    expect(scheduler.scheduled, isEmpty);
  });

  test('si reprogramar al arrancar falla, no rompe el arranque', () async {
    final reminder = await reminderWith({'reminderEnabled': true});
    scheduler.failToSchedule = true;

    await expectLater(reminder.restore(), completes);
  });

  test('cerrar sesión lo cancela y lo apaga; si ya estaba apagado no toca nada', () async {
    final on = await reminderWith({'reminderEnabled': true});
    await on.stop();
    expect(scheduler.cancels, 1);
    expect(on.preferences.reminderEnabled, isFalse);

    final off = await reminderWith({});
    await off.stop();
    expect(scheduler.cancels, 0);
  });
}
