// Series de las gráficas de estadísticas a partir de los eventos del servidor.
//
// Función pura sobre stats_buckets.dart: la usan la pantalla de estadísticas,
// la portada y el perfil, que antes repetían cada una su propio cálculo de 7
// días con solo la última finalización de cada elemento.
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

/// Desde cuándo hay que pedir eventos: el inicio del cubo más viejo del
/// periodo más largo (mensual, 6 meses). Con eso sirven todos los periodos.
DateTime statsWindowStart({DateTime? now}) => dateRange(StatPeriod.monthly, now: now).first;

class StatSeries {
  final List<String> labels;
  final Map<StatType, List<int>> _byType;

  const StatSeries._(this.labels, this._byType);

  List<int> of(StatType type) => _byType[type]!;

  int totalOf(StatType type) => of(type).fold(0, (sum, value) => sum + value);

  /// Suma de las tres series por cubo (la gráfica de línea).
  List<int> get total => List.generate(
    labels.length,
    (i) => StatType.values.fold(0, (sum, type) => sum + of(type)[i]),
  );
}

StatSeries buildStatSeries(StatsEvents events, StatPeriod period, {DateTime? now}) {
  final buckets = dateRange(period, now: now);
  List<int> count(Iterable<DateTime> dates) => bucketCounts(dates.toList(), buckets, period);

  return StatSeries._(
    buckets.map((bucket) => labelFor(bucket, period)).toList(),
    {
      StatType.exercises: count(events.exerciseCompletions.map((e) => e.completedAt)),
      StatType.trainings: count(events.trainingCompletions.map((e) => e.completedAt)),
      StatType.created: count(events.created.map((e) => e.createdAt)),
    },
  );
}
