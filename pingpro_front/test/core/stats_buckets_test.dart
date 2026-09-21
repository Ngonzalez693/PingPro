import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stats_buckets.dart';

void main() {
  // Miércoles 16 de septiembre de 2026. Se fija la fecha para que las pruebas
  // no dependan del día en que se ejecuten.
  final wednesday = DateTime(2026, 9, 16, 14, 30);

  group('dateRange diario', () {
    test('son los últimos 7 días y el último es hoy', () {
      final range = dateRange(StatPeriod.daily, now: wednesday);

      expect(range, hasLength(7));
      expect(range.first, DateTime(2026, 9, 10));
      expect(range.last, DateTime(2026, 9, 16));
    });

    test('los cubos empiezan a medianoche', () {
      final range = dateRange(StatPeriod.daily, now: wednesday);

      expect(range.every((d) => d.hour == 0 && d.minute == 0), isTrue);
    });
  });

  group('dateRange semanal', () {
    test('la semana en curso empieza en lunes, no en domingo', () {
      final range = dateRange(StatPeriod.weekly, now: wednesday);

      // El bug anterior usaba `weekday % 7`, que para este miércoles daba
      // el domingo 13 en vez del lunes 14.
      expect(range.last, DateTime(2026, 9, 14));
      expect(range.last.weekday, DateTime.monday);
    });

    test('un domingo cuenta en la semana que abrió el lunes anterior', () {
      final sunday = DateTime(2026, 9, 20, 9);
      final range = dateRange(StatPeriod.weekly, now: sunday);

      expect(range.last, DateTime(2026, 9, 14));
      expect(range.last.weekday, DateTime.monday);
    });

    test('un lunes se queda en su propia semana', () {
      final monday = DateTime(2026, 9, 14, 0, 5);
      final range = dateRange(StatPeriod.weekly, now: monday);

      expect(range.last, DateTime(2026, 9, 14));
    });

    test('son 8 lunes consecutivos', () {
      final range = dateRange(StatPeriod.weekly, now: wednesday);

      expect(range, hasLength(8));
      expect(range.every((d) => d.weekday == DateTime.monday), isTrue);
      expect(range.first, DateTime(2026, 7, 27));
    });
  });

  group('dateRange mensual', () {
    test('son los últimos 6 meses, cada uno en su día 1', () {
      final range = dateRange(StatPeriod.monthly, now: wednesday);

      expect(range, hasLength(6));
      expect(range.first, DateTime(2026, 4, 1));
      expect(range.last, DateTime(2026, 9, 1));
    });

    test('cruza el cambio de año hacia atrás', () {
      final range = dateRange(StatPeriod.monthly, now: DateTime(2026, 2, 10));

      expect(range.first, DateTime(2025, 9, 1));
      expect(range.last, DateTime(2026, 2, 1));
    });
  });

  group('belongsToBucket semanal', () {
    final monday = DateTime(2026, 9, 14);

    test('el propio lunes a medianoche entra', () {
      expect(belongsToBucket(monday, monday, StatPeriod.weekly), isTrue);
    });

    test('el domingo siguiente a última hora todavía entra', () {
      final sunday = DateTime(2026, 9, 20, 23, 59);
      expect(belongsToBucket(sunday, monday, StatPeriod.weekly), isTrue);
    });

    test('el lunes siguiente ya no entra', () {
      final nextMonday = DateTime(2026, 9, 21);
      expect(belongsToBucket(nextMonday, monday, StatPeriod.weekly), isFalse);
    });

    test('el domingo anterior no entra', () {
      final previousSunday = DateTime(2026, 9, 13, 23, 59);
      expect(belongsToBucket(previousSunday, monday, StatPeriod.weekly), isFalse);
    });
  });

  group('bucketCounts', () {
    test('reparte las fechas en su cubo', () {
      final buckets = dateRange(StatPeriod.daily, now: wednesday);
      final dates = [
        DateTime(2026, 9, 16, 8),
        DateTime(2026, 9, 16, 20),
        DateTime(2026, 9, 14, 12),
      ];

      final counts = bucketCounts(dates, buckets, StatPeriod.daily);

      expect(counts.last, 2);          // 16 de septiembre
      expect(counts[4], 1);            // 14 de septiembre
      expect(counts.reduce((a, b) => a + b), 3);
    });

    test('ignora lo que queda fuera del rango', () {
      final buckets = dateRange(StatPeriod.daily, now: wednesday);
      final counts = bucketCounts([DateTime(2020, 1, 1)], buckets, StatPeriod.daily);

      expect(counts.reduce((a, b) => a + b), 0);
    });

    test('sin fechas da todo ceros', () {
      final buckets = dateRange(StatPeriod.weekly, now: wednesday);
      final counts = bucketCounts([], buckets, StatPeriod.weekly);

      expect(counts, hasLength(8));
      expect(counts.every((c) => c == 0), isTrue);
    });
  });

  group('labelFor', () {
    test('diario usa la inicial del día', () {
      expect(labelFor(DateTime(2026, 9, 14), StatPeriod.daily), 'L');
      expect(labelFor(DateTime(2026, 9, 16), StatPeriod.daily), 'X');
      expect(labelFor(DateTime(2026, 9, 20), StatPeriod.daily), 'D');
    });

    test('semanal usa el día y el mes del lunes', () {
      expect(labelFor(DateTime(2026, 9, 14), StatPeriod.weekly), '14 Sep');
      expect(labelFor(DateTime(2026, 1, 5), StatPeriod.weekly), '5 Ene');
    });

    test('mensual usa el mes abreviado', () {
      expect(labelFor(DateTime(2026, 9, 1), StatPeriod.monthly), 'Sep');
      expect(labelFor(DateTime(2026, 12, 1), StatPeriod.monthly), 'Dic');
    });
  });
}
