import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppPreferences> loaded(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = AppPreferences.forTesting();
    await prefs.load();
    return prefs;
  }

  test('por defecto no reduce animaciones', () async {
    final prefs = await loaded({});

    expect(prefs.reduceMotion, isFalse);
  });

  test('carga lo guardado en el teléfono', () async {
    final prefs = await loaded({'reduceMotion': true});

    expect(prefs.reduceMotion, isTrue);
  });

  test('cambiarla avisa al instante y queda guardada para el próximo arranque', () async {
    final prefs = await loaded({});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReduceMotion(true);

    expect(prefs.reduceMotion, isTrue);
    expect(notified, 1);
    final nextLaunch = AppPreferences.forTesting();
    await nextLaunch.load();
    expect(nextLaunch.reduceMotion, isTrue);
  });

  test('poner el mismo valor no avisa', () async {
    final prefs = await loaded({'reduceMotion': true});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReduceMotion(true);

    expect(notified, 0);
  });

  test('el recordatorio empieza apagado y a las 19:00', () async {
    final prefs = await loaded({});

    expect(prefs.reminderEnabled, isFalse);
    expect(prefs.reminderTime, const TimeOfDay(hour: 19, minute: 0));
  });

  test('carga el recordatorio guardado en el teléfono', () async {
    final prefs = await loaded({'reminderEnabled': true, 'reminderMinutes': 7 * 60 + 30});

    expect(prefs.reminderEnabled, isTrue);
    expect(prefs.reminderTime, const TimeOfDay(hour: 7, minute: 30));
  });

  test('encenderlo y cambiar la hora avisa y queda guardado', () async {
    final prefs = await loaded({});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReminderEnabled(true);
    await prefs.setReminderTime(const TimeOfDay(hour: 8, minute: 15));

    expect(notified, 2);
    final nextLaunch = AppPreferences.forTesting();
    await nextLaunch.load();
    expect(nextLaunch.reminderEnabled, isTrue);
    expect(nextLaunch.reminderTime, const TimeOfDay(hour: 8, minute: 15));
  });

  test('poner la misma hora no avisa', () async {
    final prefs = await loaded({'reminderMinutes': 19 * 60});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReminderTime(const TimeOfDay(hour: 19, minute: 0));

    expect(notified, 0);
  });
}
