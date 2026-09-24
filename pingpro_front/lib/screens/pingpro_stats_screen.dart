// Estadísticas (resumen): gráfica de línea con el total y gráfica de barras
// del tipo seleccionado, por periodo diario, semanal o mensual.
//
// Los datos son el historial real de StatsState (cada repetición cuenta y
// "Creados" es lo propio que no se ha borrado); las series las calcula
// core/stats_series.dart. Esta pantalla solo elige periodo y tipo, y pinta.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/stats_series.dart';

class PingproStatsScreen extends StatefulWidget {
  const PingproStatsScreen({super.key});

  @override
  State<PingproStatsScreen> createState() => _PingproStatsScreenState();
}

class _PingproStatsScreenState extends State<PingproStatsScreen> {
  StatPeriod _period = StatPeriod.weekly;
  StatType _activeType = StatType.exercises;

  @override
  void initState() {
    super.initState();
    StatsState.instance.load();
  }

  void _onPeriodSelected(StatPeriod p) => setState(() => _period = p);
  void _onTypeSelected(StatType t) => setState(() => _activeType = t);

  String _titleFor(StatType type) {
    switch (type) {
      case StatType.exercises:
        return 'Ejercicios';
      case StatType.trainings:
        return 'Entrenamientos';
      case StatType.created:
        return 'Creados';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: StatsState.instance,
          builder: (context, _) {
            final stats = StatsState.instance;
            final series = buildStatSeries(stats.events, _period);

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      Text('Estadísticas', style: TextStyles.title),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Period tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPeriodTab('Diario', StatPeriod.daily),
                      const SizedBox(width: 8),
                      _buildPeriodTab('Semanal', StatPeriod.weekly),
                      const SizedBox(width: 8),
                      _buildPeriodTab('Mensual', StatPeriod.monthly),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== Gráfico principal (línea) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StatisticsChart(
                    values: series.total,
                    labels: series.labels,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== Summary icons (real) =====
                SummaryIconRow(
                  active: _activeType,
                  onSelected: _onTypeSelected,
                  exercisesCount: series.totalOf(StatType.exercises),
                  trainingsCount: series.totalOf(StatType.trainings),
                  createdCount: series.totalOf(StatType.created),
                ),

                const SizedBox(height: 8),

                // ===== Gráfico secundario (barras) =====
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: SizedBox(
                    height: 200,
                    child: StatisticsSecondaryChart(
                      title: _titleFor(_activeType),
                      values: series.of(_activeType),
                      labels: series.labels,
                    ),
                  ),
                ),

                if (stats.isLoading && !stats.loadedOnce)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (stats.error != null && !stats.loadedOnce)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No se pudieron cargar las estadísticas', style: TextStyles.paragraph),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, StatPeriod p) {
    final selected = _period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodSelected(p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.secundary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyles.buttons),
        ),
      ),
    );
  }
}
