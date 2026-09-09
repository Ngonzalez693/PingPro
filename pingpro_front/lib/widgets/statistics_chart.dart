// Gráfica de línea de actividad (fl_chart). La usan Home, Perfil y
// Estadísticas con series distintas.
//
// Solo dibuja: recibe `values` y `labels` ya calculados, no sabe de fechas ni
// de periodos. Ambas listas deben tener el mismo largo.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class StatisticsChart extends StatelessWidget {
  final List<int> values;       // valores por punto (orden cronológico)
  final List<String> labels;    // etiquetas abajo (mismo largo que values)

  const StatisticsChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // Sin actividad todos los valores son 0; forzar maxY a 1 evita que fl_chart
    // reciba un rango vacío y la gráfica quede en blanco.
    final maxY = (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b)).toDouble();
    final maxYAdj = (maxY == 0 ? 1 : maxY);

    final spots = <FlSpot>[
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].toDouble()),
    ];

    return Container(
      height: 160, // 🔹 misma altura que usabas
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.isEmpty ? 0 : values.length - 1).toDouble(),
          minY: 0,
          maxY: maxYAdj.toDouble(),
          gridData: FlGridData(show: true, horizontalInterval: (maxYAdj / 4).clamp(1, double.infinity)),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: AppColors.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary,
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1),
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
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
