import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/models/exercise_model.dart';

enum StatType { exercises, trainings, created }
enum StatPeriod { daily, weekly, monthly }

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
    ExercisesState.instance.load();
  }

  void _onPeriodSelected(StatPeriod p) {
    setState(() => _period = p);
  }

  void _onTypeSelected(StatType t) {
    setState(() => _activeType = t);
  }

  int _countDoneByPeriod(List<ExerciseModel> all, StatPeriod p) {
    final now = DateTime.now();
    bool inPeriod(DateTime d) {
      switch (p) {
        case StatPeriod.daily:
          return d.year == now.year && d.month == now.month && d.day == now.day;
        case StatPeriod.weekly:
          // últimos 7 días incluyendo hoy
          return d.isAfter(now.subtract(const Duration(days: 6))) &&
                 d.isBefore(now.add(const Duration(days: 1)));
        case StatPeriod.monthly:
          return d.year == now.year && d.month == now.month;
      }
    }

    return all
        .where((e) => e.completedAt != null && inPeriod(e.completedAt!))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ExercisesState.instance,
          builder: (context, _) {
            final s = ExercisesState.instance;

            // Lista completa de ejercicios hechos
            final done = s.all.where((e) => e.completedAt != null).toList();

            // Conteos para el row de resumen (ejercicios según período elegido)
            final exercisesCount = _countDoneByPeriod(done, _period);
            final trainingsCount = 0; // lo conectamos cuando hagamos trainings por usuario
            final createdCount = 0;   // si luego llevas métrica de creados

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textWhite,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      Text('Estadísticas', style: TextStyles.title),
                      const Spacer(),
                      const SizedBox(width: 48), // placeholder for symmetry
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

                // Main statistics chart (lo dejas igual por ahora)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: StatisticsChart(),
                ),

                const SizedBox(height: 16),

                // Summary icons con conteos reales de ejercicios
                SummaryIconRow(
                  active: _activeType,
                  onSelected: _onTypeSelected,
                  exercisesCount: exercisesCount,
                  trainingsCount: trainingsCount,
                  createdCount: createdCount,
                ),

                const SizedBox(height: 8),

                // Secondary chart (título dinámico, el widget ya lo maneja)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: SizedBox(
                    height: 200,
                    child: StatisticsSecondaryChart(
                      title: _activeType == StatType.exercises
                          ? 'Ejercicios últimos 7 días'
                          : _activeType == StatType.trainings
                              ? 'Entrenamientos últimos 7 días'
                              : 'Creados últimos 7 días',
                    ),
                  ),
                ),

                // Loader sencillo si aún no cargaron los ejercicios
                if (s.isLoading && !s.loadedOnce)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
