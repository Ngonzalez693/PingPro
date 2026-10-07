import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/reminder_time.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  const seven = TimeOfDay(hour: 19, minute: 0);

  group('nextDailyAt', () {
    test('si la hora todavía no pasó, es hoy', () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 7, 18, 30);

      expect(nextDailyAt(seven, now), tz.TZDateTime(tz.UTC, 2026, 10, 7, 19));
    });

    test('si ya pasó, es mañana', () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 7, 20, 15);

      expect(nextDailyAt(seven, now), tz.TZDateTime(tz.UTC, 2026, 10, 8, 19));
    });

    test('justo a la hora cuenta como pasada: mañana', () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 7, 19);

      expect(nextDailyAt(seven, now), tz.TZDateTime(tz.UTC, 2026, 10, 8, 19));
    });

    test('el 31 de diciembre pasa al año siguiente', () {
      final now = tz.TZDateTime(tz.UTC, 2026, 12, 31, 20);

      expect(nextDailyAt(seven, now), tz.TZDateTime(tz.UTC, 2027, 1, 1, 19));
    });
  });

  test('formatReminderTime usa 24 h con ceros', () {
    expect(formatReminderTime(seven), '19:00');
    expect(formatReminderTime(const TimeOfDay(hour: 7, minute: 5)), '07:05');
  });
}
