import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/summary_icon.dart';
import 'package:pingpro_front/widgets/training_card.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';

class PingproProfileScreen extends StatefulWidget {
  const PingproProfileScreen({super.key});

  @override
  State<PingproProfileScreen> createState() => _PingproProfileScreenState();
}

class _PingproProfileScreenState extends State<PingproProfileScreen> {
  // Placeholder (cuando marquemos trainings hechos por usuario lo llenamos)
  final List<TrainingModel> _recentTrainings = [];

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load(); // idempotente
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await ExercisesState.instance.toggleFavorite(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error actualizando favorito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ExercisesState.instance,
          builder: (context, _) {
            final s = ExercisesState.instance;

            // ejercicios completados (recientes primero)
            final List<ExerciseModel> done = s.all
                .where((e) => e.completedAt != null)
                .toList()
              ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
            final recentExercises = done.take(5).toList();

            final exercisesCount = done.length;
            final trainingsCount = _recentTrainings.length; // placeholder
            final createdCount = 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              AssetImage('assets/images/avatar_placeholder.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyles.title),
                              Text('Ver perfil', style: TextStyles.paragraph),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings,
                              color: AppColors.textWhite),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/editProfile'),
                        ),
                      ],
                    ),
                  ),

                  // Estadísticas
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Estadísticas', style: TextStyles.subTitle),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/stats'),
                      child: const StatisticsChart(),
                    ),
                  ),

                  // Resumen
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/stats'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SummaryIcon(
                            assetPath: 'assets/icons/exercise_unselected.svg',
                            count: exercisesCount,
                            label: 'Ejercicios',
                          ),
                          SummaryIcon(
                            assetPath: 'assets/icons/training_unselected.svg',
                            count: trainingsCount,
                            label: 'Entrenamientos',
                          ),
                          SummaryIcon(
                            assetPath: 'assets/icons/create_unselected.svg',
                            count: createdCount,
                            label: 'Creados',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actividad reciente
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Actividad reciente', style: TextStyles.title),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Últimos ejercicios', style: TextStyles.subTitle),
                  ),
                  const SizedBox(height: 8),

                  if (s.isLoading && !s.loadedOnce && recentExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (recentExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Aún no has hecho ningún ejercicio. ¡Comienza ahora!',
                        style: TextStyles.paragraph,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (int i = 0; i < recentExercises.length; i++)
                            Padding(
                              padding: EdgeInsets.only(bottom: i == recentExercises.length - 1 ? 0 : 12),
                              child: ExerciseCard(
                                exercise: recentExercises[i],
                                showTopDivider: i != 0,
                                onFavoritePressed: () =>
                                    _toggleFavorite(recentExercises[i].id),
                                onViewPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/exerciseDetail',
                                    arguments: {
                                      'exercise': recentExercises[i],
                                      'returnRoute': '/profile',
                                    },
                                  );
                                  // No hace falta setState: el store se encarga
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Últimos entrenamientos (placeholder)
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        Text('Últimos entrenamientos', style: TextStyles.subTitle),
                  ),
                  const SizedBox(height: 8),
                  if (_recentTrainings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Aún no has realizado ningún entrenamiento. ¡Pruébalos ahora!',
                        style: TextStyles.paragraph,
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentTrainings.length.clamp(0, 3),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final t = _recentTrainings[i];
                          return SizedBox(
                            width: 120,
                            child: TrainingCard(
                              training: t,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/trainingDetail',
                                arguments: t,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
