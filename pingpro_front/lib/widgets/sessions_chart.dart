// Barra apilada por cubo con las sesiones entrenadas (S1, S2, S3, sin
// sesión). Mismo marco y eje que StatisticsSecondaryChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/chart_axis.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';
import 'package:pingpro_front/core/text_styles.dart';

const _sessionColors = <int?, Color>{
  1: AppColors.primary,
  2: AppColors.accent,
  3: AppColors.textBlack,
  null: AppColors.textGray,
};

const _sessionNames = <int?, String>{1: 'S1', 2: 'S2', 3: 'S3', null: 'Sin sesión'};

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
            barGroups: [for (var i = 0; i < labels.length; i++) _buildGroup(i, totals[i])],
            titlesData: _buildTitles(axis),
          )),
        ),
        const SizedBox(height: 8),
        _buildLegend(),
      ],
    );
  }

  BarChartGroupData _buildGroup(int i, int total) {
    final stack = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final key in sessionKeys) {
      final to = from + perSession[key]![i];
      if (to > from) stack.add(BarChartRodStackItem(from, to, _sessionColors[key]!));
      from = to;
    }
    return BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: total.toDouble(),
        width: 14,
        rodStackItems: stack,
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(4),
      ),
    ]);
  }

  FlTitlesData _buildTitles(ChartAxis axis) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: axis.interval,
          getTitlesWidget: (v, meta) => Text(axis.label(v), style: TextStyles.aditional),
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
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[i], style: TextStyles.aditional),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      children: [
        for (final key in sessionKeys)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: _sessionColors[key]),
              const SizedBox(width: 4),
              Text(_sessionNames[key]!, style: TextStyles.aditional),
            ],
          ),
      ],
    );
  }
}
