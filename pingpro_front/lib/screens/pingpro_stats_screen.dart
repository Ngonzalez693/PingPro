// Estadísticas detalladas: gráfica de línea (total) + gráfica de barras del
// tipo seleccionado, con periodo diario, semanal o mensual.
//
// Todo se calcula en el cliente a partir de los `completedAt` que ya están en
// los stores. El backend no tiene endpoints de estadísticas.
//
// El cálculo va en tres pasos: _dateRange() genera los cubos del periodo,
// _belongsToBucket() decide en cuál cae cada fecha y _bucketCounts() los
// cuenta. Es la versión completa de lo que Home y Perfil hacen en línea solo
// para 7 días.
//
// La serie "Creados" siempre da cero: la creación de ejercicios todavía no
// guarda nada (ver pingpro_create_screen.dart).
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';

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

  void _onPeriodSelected(StatPeriod p) => setState(() => _period = p);
  void _onTypeSelected(StatType t) => setState(() => _activeType = t);

  // ==== Helpers de bucketing ====
  List<DateTime> _dateRange(StatPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case StatPeriod.daily:   // últimos 7 días (izq->der: más viejo -> hoy)
        return List.generate(7, (i) {
          final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
          return d;
        });
      case StatPeriod.weekly:  // últimas 8 semanas (lunes a domingo)
        final today = DateTime(now.year, now.month, now.day);
        // OJO: `weekday % 7` da 0 para domingo y 1 para lunes, así que esto
        // aterriza en DOMINGO, no en lunes como dice el comentario original.
        // Para semanas de lunes a domingo sería `today.weekday - 1`.
        final monday = today.subtract(Duration(days: (today.weekday % 7))); // lunes = weekday 1, domingo=7
        return List.generate(8, (i) => monday.subtract(Duration(days: (7 * (7 - i))))); // 8 inicios de semana
      case StatPeriod.monthly: // últimos 6 meses
        return List.generate(6, (i) {
          final d = DateTime(now.year, now.month - (5 - i), 1);
          return DateTime(d.year, d.month, 1);
        });
    }
  }

  String _labelFor(DateTime d, StatPeriod p) {
    const dias = ['D','L','M','X','J','V','S']; // usaremos L..D en daily
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    switch (p) {
      case StatPeriod.daily:
        return dias[d.weekday % 7]; // Mon=1 -> 'L', ..., Sun=7 -> 'D'
      case StatPeriod.weekly:
        // etiqueta como "Sem X" (número de semana simple: semana del año aproximada)
        final firstJan = DateTime(d.year, 1, 1);
        final weekNumber = ((d.difference(firstJan).inDays) / 7).floor() + 1;
        return 'Sem $weekNumber';
      case StatPeriod.monthly:
        return meses[d.month - 1];
    }
  }

  bool _belongsToBucket(DateTime when, DateTime bucket, StatPeriod p) {
    switch (p) {
      case StatPeriod.daily:   // mismo día
        return when.year == bucket.year &&
               when.month == bucket.month &&
               when.day == bucket.day;
      case StatPeriod.weekly:  // dentro de esa semana (bucket es lunes)
        final start = bucket; // lunes 00:00
        final end = start.add(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(end);
      case StatPeriod.monthly: // mismo mes
        return when.year == bucket.year && when.month == bucket.month;
    }
  }

  List<int> _bucketCounts(List<DateTime> dates, StatPeriod p) {
    final buckets = _dateRange(p);
    final counts = List<int>.filled(buckets.length, 0);
    for (final dt in dates) {
      for (int i = 0; i < buckets.length; i++) {
        if (_belongsToBucket(dt, buckets[i], p)) {
          counts[i] += 1;
          break;
        }
      }
    }
    return counts;
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
            final buckets = _dateRange(_period);
            final labels = buckets.map((b) => _labelFor(b, _period)).toList();

            // series
            final exercisesSeries = _bucketCounts(exercisesDates, _period);
            final trainingsSeries = _bucketCounts(trainingsDates, _period);
            final createdSeries   = _bucketCounts(createdDates,   _period);

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
