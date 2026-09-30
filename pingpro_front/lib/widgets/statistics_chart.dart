// Gráfica de línea de actividad (fl_chart). La usan Home, Perfil y
// Estadísticas con series distintas.
//
// Solo dibuja: recibe `values` y `labels` ya calculados, no sabe de fechas ni
// de periodos. Ambas listas deben tener el mismo largo.
//
// La línea se traza de izquierda a derecha al aparecer y cada vez que cambian
// los valores (p. ej. al cambiar de periodo en Estadísticas). Ejes y grilla
// se muestran enteros desde el principio. Ver core/chart_reveal.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/chart_axis.dart';
import 'package:pingpro_front/core/chart_reveal.dart';

class StatisticsChart extends StatefulWidget {
  final List<int> values;       // valores por punto (orden cronológico)
  final List<String> labels;    // etiquetas abajo (mismo largo que values)

  const StatisticsChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  State<StatisticsChart> createState() => _StatisticsChartState();
}

class _StatisticsChartState extends State<StatisticsChart>
    with SingleTickerProviderStateMixin {
  static const _labelStyle = TextStyle(fontSize: 11, color: Colors.white);

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reveal.isAnimating || _reveal.isCompleted) return;
    _play();
  }

  @override
  void didUpdateWidget(StatisticsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.values, widget.values)) return;
    _play();
  }

  void _play() {
    // Con "reducir animaciones" activado, la línea aparece completa.
    if (MediaQuery.of(context).disableAnimations) {
      _reveal.value = 1;
      return;
    }
    _reveal.forward(from: 0);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // 🔹 misma altura que usabas
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => _buildChart(_progress.value),
      ),
    );
  }

  Widget _buildChart(double progress) {
    final values = widget.values;
    final axis = ChartAxis.forValues(values);
    final maxX = (values.isEmpty ? 0 : values.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: axis.max,
        // Red de seguridad: nada se pinta fuera de los ejes.
        clipData: const FlClipData.all(),
        gridData: FlGridData(show: true, horizontalInterval: axis.interval),
        borderData: FlBorderData(show: false),
        lineBarsData: [_buildLine(maxX, progress)],
        titlesData: _buildTitles(axis),
      ),
      // La transición propia de fl_chart suavizaría cada frame del trazo y
      // lo dejaría a destiempo: el trazo ya es la animación.
      duration: Duration.zero,
    );
  }

  LineChartBarData _buildLine(double maxX, double progress) {
    final values = widget.values;
    return LineChartBarData(
      spots: [
        for (int i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i].toDouble()),
      ],
      isCurved: true,
      // La curva es un spline que pasa por los puntos, y entre una
      // racha de ceros y un pico se pasa de largo: bajaba de 0 y subía
      // del máximo, que es la curva saliéndose de los ejes.
      preventCurveOverShooting: true,
      barWidth: 3,
      gradient: LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0),
        ],
        stops: revealStops(progress),
      ),
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, _) =>
            isRevealed(x: spot.x, maxX: maxX, progress: progress),
      ),
    );
  }

  FlTitlesData _buildTitles(ChartAxis axis) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: axis.interval,
          getTitlesWidget: (v, meta) => Text(axis.label(v), style: _labelStyle),
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
            final labels = widget.labels;
            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[i], style: _labelStyle),
            );
          },
        ),
      ),
    );
  }
}
