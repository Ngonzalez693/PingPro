// Pestaña 1: portada con banners, recomendaciones y un resumen de actividad.
//
// Dispara la carga de los tres stores (ejercicios, entrenamientos y
// estadísticas) en initState. Como load() es idempotente, si otra pestaña ya
// cargó no se repite la petición.
//
// El bloque de estadísticas es la gráfica de los últimos 7 días de
// StatsState, calculada con core/stats_series.dart como en Estadísticas.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/stats_series.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/image_banner_carousel.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/training_card.dart';

class PingproHomeScreen extends StatefulWidget {
  const PingproHomeScreen({super.key});
  @override
  State<PingproHomeScreen> createState() => _PingproHomeScreenState();
}

class _PingproHomeScreenState extends State<PingproHomeScreen> {
  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
    TrainingsState.instance.load();
    StatsState.instance.load();
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await ExercisesState.instance.toggleFavorite(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar favorito')),
        );
      }
    }
  }

  // Mismo alto que la gráfica para que el layout no salte al fallar la carga.
  Widget _buildStatsError() {
    return const SizedBox(
      height: 160,
      child: Center(
        child: Text(
          'No se pudieron cargar las estadísticas',
          style: TextStyles.paragraph,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'PingPro',
                style: TextStyles.title.copyWith(
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, $displayName',
              style: TextStyles.paragraph.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const ImageBannerCarousel(),
            const SizedBox(height: 32),

            // Recomendaciones
            Text('Recomendaciones', style: TextStyles.title),
            const SizedBox(height: 12),

            // Entrenamientos
            Text('Entrenamientos', style: TextStyles.paragraph),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: AnimatedBuilder(
                animation: TrainingsState.instance,
                builder: (context, _) {
                  final ts = TrainingsState.instance;

                  if (ts.isLoading && !ts.loadedOnce) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (ts.error != null) {
                    return Center(
                      child: Text(
                        'Error al cargar entrenamientos: ${ts.error}',
                      ),
                    );
                  }

                  final List<TrainingModel> trainings = ts.all.take(4).toList();
                  if (trainings.isEmpty) {
                    return const Center(child: Text('No hay entrenamientos'));
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: trainings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final t = trainings[i];
                      return SizedBox(
                        width: 120,
                        child: TrainingCard(
                          training: t,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/trainingDetail',
                              arguments: t,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            //Ejercicios
            Text('Ejercicios', style: TextStyles.paragraph),
            const SizedBox(height: 16),

            AnimatedBuilder(
              animation: ExercisesState.instance,
              builder: (context, _) {
                final s = ExercisesState.instance;

                if (s.isLoading && !s.loadedOnce) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.error != null) {
                  return Text('Error al cargar ejercicios: ${s.error}');
                }

                final List<ExerciseModel> exercises = s.all.take(2).toList();
                if (exercises.isEmpty) {
                  return const Text('No hay ejercicios disponibles');
                }

                return Column(
                  children: [
                    for (final ex in exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          onFavoritePressed: () => _toggleFavorite(ex.id),
                          onViewPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PingproExerciseDetailScreen(
                                      exercise:
                                          ex, // puedes seguir pasando el objeto
                                      returnRoute: '/home',
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Estadísticas
            Text('Estadísticas', style: TextStyles.subTitle),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/stats'),
              child: AnimatedBuilder(
                animation: StatsState.instance,
                builder: (context, _) {
                  final stats = StatsState.instance;
                  if (stats.isLoading && !stats.loadedOnce) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  if (stats.error != null && !stats.loadedOnce) {
                    return _buildStatsError();
                  }
                  final week = buildStatSeries(stats.events, StatPeriod.daily);
                  return StatisticsChart(values: week.total, labels: week.labels);
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
