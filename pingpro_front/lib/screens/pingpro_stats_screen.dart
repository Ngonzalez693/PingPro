import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';

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
    TrainingsState.instance.load();
  }

  void _onPeriodSelected(StatPeriod p) {
    setState(() => _period = p);
  }

  void _onTypeSelected(StatType t) {
    setState(() => _activeType = t);
  }

  // Helpers de conteo por período
  bool _inPeriod(DateTime d, StatPeriod p, DateTime now) {
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

  int _countExercisesByPeriod(List<ExerciseModel> all, StatPeriod p) {
    final now = DateTime.now();
    return all
        .where((e) => e.completedAt != null && _inPeriod(e.completedAt!, p, now))
        .length;
  }

  int _countTrainingsByPeriod(List<TrainingModel> all, StatPeriod p) {
    final now = DateTime.now();
    return all
        .where((t) => t.completedAt != null && _inPeriod(t.completedAt!, p, now))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ExercisesState.instance, TrainingsState.instance]),
          builder: (context, _) {
            final es = ExercisesState.instance;
            final ts = TrainingsState.instance;

            // Listas completas de hechos
            final doneExercises =
                es.all.where((e) => e.completedAt != null).toList();
            final doneTrainings =
                ts.all.where((t) => t.completedAt != null).toList();

            // Conteos por período actual
            final exercisesCount = _countExercisesByPeriod(doneExercises, _period);
            final trainingsCount = _countTrainingsByPeriod(doneTrainings, _period);
            final createdCount = 0; // conecta esto si llevas métrica de creados

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
                      const SizedBox(width: 48), // placeholder para simetría
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

                // Gráfico principal (placeholder actual)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: StatisticsChart(),
                ),

                const SizedBox(height: 16),

                // Summary icons (conteos reales)
                SummaryIconRow(
                  active: _activeType,
                  onSelected: _onTypeSelected,
                  exercisesCount: exercisesCount,
                  trainingsCount: trainingsCount,
                  createdCount: createdCount,
                ),

                const SizedBox(height: 8),

                // Gráfico secundario (solo cambia el título)
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

                // Loader sencillo si alguna store aún no cargó nada
                if ((es.isLoading && !es.loadedOnce) ||
                    (ts.isLoading && !ts.loadedOnce))
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
