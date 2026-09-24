// Estadísticas detalladas: gráfica de línea (total) + gráfica de barras del
// tipo seleccionado, con periodo diario, semanal o mensual.
//
// Todo se calcula en el cliente a partir de los `completedAt` que ya están en
// los stores. El backend no tiene endpoints de estadísticas.
//
// El reparto en cubos vive en core/stats_buckets.dart, que son funciones puras
// y con pruebas. Esta pantalla solo elige el periodo y pinta.
//
// La serie "Creados" siempre da cero: la creación de ejercicios todavía no
// guarda nada (ver pingpro_create_screen.dart).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';

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

  void _onPeriodSelected(StatPeriod p) => setState(() => _period = p);
  void _onTypeSelected(StatType t) => setState(() => _activeType = t);

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

            // fechas de eventos (completedAt) para cada tipo
            final exercisesDates = es.all
                .where((e) => e.completedAt != null)
                .map((e) => e.completedAt!)
                .toList();

            final trainingsDates = ts.all
                .where((t) => t.completedAt != null)
                .map((t) => t.completedAt!)
                .toList();

            final createdDates = <DateTime>[]; // si luego guardas "creados", pon aquí esas fechas

            // buckets + labels
            final buckets = dateRange(_period);
            final labels = buckets.map((b) => labelFor(b, _period)).toList();

            // series
            final exercisesSeries = bucketCounts(exercisesDates, buckets, _period);
            final trainingsSeries = bucketCounts(trainingsDates, buckets, _period);
            final createdSeries   = bucketCounts(createdDates,   buckets, _period);

            // serie total (para el gráfico de líneas)
            final totalSeries = List<int>.generate(
              labels.length,
              (i) => exercisesSeries[i] + trainingsSeries[i] + createdSeries[i],
            );

            // conteos para Summary
            int countByPeriod(List<int> series) => series.fold<int>(0, (a, b) => a + b);
            final exercisesCount = countByPeriod(exercisesSeries);
            final trainingsCount = countByPeriod(trainingsSeries);
            final createdCount   = countByPeriod(createdSeries);

            // datos del secundario según selección
            List<int> secondaryValues;
            switch (_activeType) {
              case StatType.exercises: secondaryValues = exercisesSeries; break;
              case StatType.trainings: secondaryValues = trainingsSeries; break;
              case StatType.created:   secondaryValues = createdSeries;   break;
            }

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
                    values: totalSeries,
                    labels: labels,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== Summary icons (real) =====
                SummaryIconRow(
                  active: _activeType,
                  onSelected: _onTypeSelected,
                  exercisesCount: exercisesCount,
                  trainingsCount: trainingsCount,
                  createdCount: createdCount,
                ),

                const SizedBox(height: 8),

                // ===== Gráfico secundario (barras) =====
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: SizedBox(
                    height: 200, // 🔹 misma altura que tenías
                    child: StatisticsSecondaryChart(
                      title: _activeType == StatType.exercises
                          ? 'Ejercicios'
                          : _activeType == StatType.trainings
                              ? 'Entrenamientos'
                              : 'Creados',
                      values: secondaryValues,
                      labels: labels,
                    ),
                  ),
                ),

                // Loader si aún no cargaron
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
