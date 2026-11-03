// Barra apilada por cubo con las sesiones entrenadas (S1, S2, S3, sin
// sesión). Comparte el mismo eje (no el marco) que StatisticsSecondaryChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/chart_axis.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';

Map<int?, Color> _sessionColors(PingProColors colors) => {
  1: colors.brand,
  2: AppColors.accent,
  3: colors.onCard,
  null: colors.muted,
};

const _sessionNames = <int?, String>{1: 'S1', 2: 'S2', 3: 'S3', null: 'Sin sesión'};

// Un solo tamaño de 11px para los dos ejes: con el de 14 por defecto las
// etiquetas semanales ("14 Sep" × 8) se solapan en un teléfono de ~360dp.
TextStyle _axisLabelStyle(PingProColors colors) => PingProText(colors).aditional.copyWith(fontSize: 11);

class SessionsChart extends StatelessWidget {
  final Map<int?, List<int>> perSession;
  final List<String> labels;

  const SessionsChart({super.key, required this.perSession, required this.labels});

  @override
  Widget build(BuildContext context) {
    final totals = [
      for (var i = 0; i < labels.length; i++)
        sessionKeys.fold(0, (sum, key) => sum + perSession[key]![i]),
    ];
    final axis = ChartAxis.forValues(totals);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            minY: 0,
            maxY: axis.max,
            gridData: FlGridData(show: true, horizontalInterval: axis.interval),
            borderData: FlBorderData(show: false),
            barGroups: [for (var i = 0; i < labels.length; i++) _buildGroup(i, totals[i], colors)],
            titlesData: _buildTitles(axis, colors),
          )),
        ),
        const SizedBox(height: 8),
        _buildLegend(colors),
      ],
    );
  }

  BarChartGroupData _buildGroup(int i, int total, PingProColors colors) {
    final sessionColors = _sessionColors(colors);
    final stack = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final key in sessionKeys) {
      final to = from + perSession[key]![i];
      if (to > from) stack.add(BarChartRodStackItem(from, to, sessionColors[key]!));
      from = to;
    }
    return BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: total.toDouble(),
        width: 14,
        rodStackItems: stack,
        color: colors.card,
        borderRadius: BorderRadius.circular(4),
      ),
    ]);
  }

  FlTitlesData _buildTitles(ChartAxis axis, PingProColors colors) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: axis.interval,
          getTitlesWidget: (v, meta) => Text(axis.label(v), style: _axisLabelStyle(colors)),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
            // Con más de 7 etiquetas (semanal) no caben todas: se muestra
            // una sí y una no para que no se amontonen.
            if (labels.length > 7 && i.isOdd) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[i], style: _axisLabelStyle(colors)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(PingProColors colors) {
    final sessionColors = _sessionColors(colors);
    return Wrap(
      spacing: 12,
      children: [
        for (final key in sessionKeys)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: sessionColors[key]),
              const SizedBox(width: 4),
              Text(_sessionNames[key]!, style: PingProText(colors).aditional),
            ],
          ),
      ],
    );
  }
}
