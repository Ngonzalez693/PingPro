// Gráfica de línea de actividad (fl_chart). La usan Home, Perfil y
// Estadísticas con series distintas.
//
// Solo dibuja: recibe `values` y `labels` ya calculados, no sabe de fechas ni
// de periodos. Ambas listas deben tener el mismo largo.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/chart_axis.dart';

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
    final axis = ChartAxis.forValues(values);

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
          maxY: axis.max,
          // Red de seguridad: nada se pinta fuera de los ejes.
          clipData: const FlClipData.all(),
          gridData: FlGridData(show: true, horizontalInterval: axis.interval),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              // La curva es un spline que pasa por los puntos, y entre una
              // racha de ceros y un pico se pasa de largo: bajaba de 0 y subía
              // del máximo, que es la curva saliéndose de los ejes.
              preventCurveOverShooting: true,
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: axis.interval,
                getTitlesWidget: (v, meta) => Text(
                  axis.label(v),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
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
