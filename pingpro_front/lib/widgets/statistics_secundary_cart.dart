// Gráfica de barras del tipo seleccionado en la pantalla de Estadísticas
// (ejercicios, entrenamientos o creados).
//
// Complementa a StatisticsChart: la de línea muestra el total y esta desglosa
// una sola serie. Comparte con ella los mismos `labels`.
//
// Nota: el nombre del archivo tiene una errata ("secundary_cart" en vez de
// "secondary_chart"); la clase sí se llama StatisticsSecondaryChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/chart_axis.dart';

class StatisticsSecondaryChart extends StatelessWidget {
  final String title;
  final List<int> values;       // valores por barra
  final List<String> labels;    // etiquetas por barra

  const StatisticsSecondaryChart({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final axis = ChartAxis.forValues(values);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: axis.max,
                gridData: FlGridData(show: true, horizontalInterval: axis.interval),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          width: 14,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: axis.interval,
                      getTitlesWidget: (v, meta) => Text(
                        axis.label(v),
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                      ),
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
                          child: Text(labels[i],
                              style: const TextStyle(fontSize: 11, color: Colors.black)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
