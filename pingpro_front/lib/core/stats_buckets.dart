// Agrupación de fechas en cubos para las gráficas de estadísticas.
//
// Son funciones puras sobre fechas, sin nada de Flutter: viven fuera de la
// pantalla para poder probarlas sin construir widgets. Quien las usa les pasa
// las fechas de los eventos de estadísticas que llegan del servidor
// (core/stats_series.dart), no fechas en memoria.
//
// Todas las fechas se construyen con el constructor DateTime(y, m, d) en vez
// de restar Duration(days: n). Duration son horas exactas, así que cruzar un
// cambio de horario deja el inicio del cubo a las 23:00 del día anterior; el
// constructor normaliza por calendario y siempre cae en medianoche.

/// Periodo que agrupa la gráfica.
enum StatPeriod { daily, weekly, monthly }

const _weekdayLabels = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
const _monthLabels = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

/// Cuántos cubos muestra cada periodo.
const _bucketCount = {
  StatPeriod.daily: 7,
  StatPeriod.weekly: 8,
  StatPeriod.monthly: 6,
};

/// Inicios de cubo en orden cronológico: el más viejo primero y el actual al
/// final, que es como se leen las gráficas de izquierda a derecha.
List<DateTime> dateRange(StatPeriod period, {DateTime? now}) {
  final today = _startOfDay(now ?? DateTime.now());
  final count = _bucketCount[period]!;

  switch (period) {
    case StatPeriod.daily:
      return List.generate(
        count,
        (i) => DateTime(today.year, today.month, today.day - (count - 1 - i)),
      );
    case StatPeriod.weekly:
      // weekday va de 1 (lunes) a 7 (domingo), así que restar weekday - 1
      // aterriza en el lunes de esta semana.
      final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
      return List.generate(
        count,
        (i) => DateTime(monday.year, monday.month, monday.day - 7 * (count - 1 - i)),
      );
    case StatPeriod.monthly:
      return List.generate(
        count,
        (i) => DateTime(today.year, today.month - (count - 1 - i), 1),
      );
  }
}

/// Etiqueta del eje X para un inicio de cubo.
String labelFor(DateTime bucket, StatPeriod period) {
  switch (period) {
    case StatPeriod.daily:
      return _weekdayLabels[bucket.weekday % 7];
    case StatPeriod.weekly:
      // Día y mes del lunes que abre la semana. Antes era un número de semana
      // aproximado (días desde el 1 de enero / 7) que se desviaba del real.
      return '${bucket.day} ${_monthLabels[bucket.month - 1]}';
    case StatPeriod.monthly:
      return _monthLabels[bucket.month - 1];
  }
}

/// Si una fecha cae dentro del cubo que empieza en `bucket`.
bool belongsToBucket(DateTime when, DateTime bucket, StatPeriod period) {
  switch (period) {
    case StatPeriod.daily:
      return when.year == bucket.year &&
          when.month == bucket.month &&
          when.day == bucket.day;
    case StatPeriod.weekly:
      final end = DateTime(bucket.year, bucket.month, bucket.day + 7);
      return !when.isBefore(bucket) && when.isBefore(end);
    case StatPeriod.monthly:
      return when.year == bucket.year && when.month == bucket.month;
  }
}

/// Cuenta cuántas fechas caen en cada cubo. Las que quedan fuera del rango
/// (más viejas que el primer cubo) simplemente no se cuentan.
List<int> bucketCounts(List<DateTime> dates, List<DateTime> buckets, StatPeriod period) {
  final counts = List<int>.filled(buckets.length, 0);
  for (final date in dates) {
    for (int i = 0; i < buckets.length; i++) {
      if (belongsToBucket(date, buckets[i], period)) {
        counts[i] += 1;
        break;
      }
    }
  }
  return counts;
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
