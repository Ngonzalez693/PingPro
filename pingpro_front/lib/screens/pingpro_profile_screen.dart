// Pestaña 5: perfil con resumen de actividad e historial reciente.
//
// "Recientes" sale de los stores en memoria (ExercisesState/TrainingsState),
// calculado ordenando por completedAt descendente.
//
// El nombre viene de FirebaseAuth.currentUser. La única petición propia es
// GET /api/users/me, solo para saber si el usuario es admin: a los admins se
// les enseña el acceso para crear contenido del catálogo.
//
// La gráfica y los tres contadores son los últimos 7 días de StatsState
// (core/stats_series.dart). Las listas de "recientes" siguen saliendo de
// ExercisesState/TrainingsState.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/session_roles.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/screens/pingpro_create_screen.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/summary_icon.dart';
import 'package:pingpro_front/widgets/training_card.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/stats_series.dart';

class PingproProfileScreen extends StatefulWidget {
  const PingproProfileScreen({super.key});

  @override
  State<PingproProfileScreen> createState() => _PingproProfileScreenState();
}

class _PingproProfileScreenState extends State<PingproProfileScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
    TrainingsState.instance.load();
    StatsState.instance.load();
    _loadRole();
  }

  // Si no se puede leer el rol se queda en no-admin: lo peor que pasa es que un
  // admin no vea el botón hasta la próxima vez. El permiso real lo comprueba el
  // backend.
  Future<void> _loadRole() async {
    final isAdmin = await SessionRoles.instance.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  void _openCatalogCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PingproCreateScreen(scope: ContentScope.catalog)),
    );
  }

  // Mismo alto que la gráfica para que el layout no salte al fallar la carga.
  Widget _buildStatsChart(StatsState stats, StatSeries week) {
    if (stats.isLoading && !stats.loadedOnce) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (stats.error != null && !stats.loadedOnce) {
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
    return StatisticsChart(values: week.total, labels: week.labels);
  }

  Widget _buildCatalogButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
          onPressed: _openCatalogCreate,
          icon: const Icon(Icons.library_add, color: AppColors.primary),
          label: const Text('Crear contenido del catálogo', style: TextStyle(color: AppColors.primary)),
        ),
      ),
    );
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
          animation: Listenable.merge([
            ExercisesState.instance,
            TrainingsState.instance,
            StatsState.instance,
          ]),
          builder: (context, _) {
            final exState = ExercisesState.instance;
            final trState = TrainingsState.instance;

            // Ejercicios hechos (recientes primero)
            final List<ExerciseModel> doneExercises =
                exState.all.where((e) => e.completedAt != null).toList()
                  ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
            final recentExercises = doneExercises.take(5).toList();

            // Trainings hechos (recientes primero)
            final List<TrainingModel> doneTrainings =
                trState.all.where((t) => t.completedAt != null).toList()
                  ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
            final recentTrainings = doneTrainings.take(3).toList();

            // Gráfica y contadores: últimos 7 días, la misma ventana para los dos.
            final stats = StatsState.instance;
            final week = buildStatSeries(stats.events, StatPeriod.daily);

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            'assets/images/avatar_placeholder.png',
                          ),
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
                          icon: const Icon(
                            Icons.settings,
                            color: AppColors.textWhite,
                          ),
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, '/editProfile'),
                        ),
                      ],
                    ),
                  ),

                  if (_isAdmin) _buildCatalogButton(),

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
                      child: _buildStatsChart(stats, week),
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
                            count: week.totalOf(StatType.exercises),
                            label: 'Ejercicios',
                          ),
                          SummaryIcon(
                            assetPath: 'assets/icons/training_unselected.svg',
                            count: week.totalOf(StatType.trainings),
                            label: 'Entrenamientos',
                          ),
                          SummaryIcon(
                            assetPath: 'assets/icons/create_unselected.svg',
                            count: week.totalOf(StatType.created),
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

                  // Últimos ejercicios (lista vertical)
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Últimos ejercicios',
                      style: TextStyles.subTitle,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (exState.isLoading &&
                      !exState.loadedOnce &&
                      recentExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
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
                              padding: EdgeInsets.only(
                                bottom:
                                    i == recentExercises.length - 1 ? 0 : 12,
                              ),
                              child: ExerciseCard(
                                exercise: recentExercises[i],
                                showTopDivider: i != 0,
                                onFavoritePressed:
                                    () =>
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
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Últimos entrenamientos
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Últimos entrenamientos',
                      style: TextStyles.subTitle,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (trState.isLoading &&
                      !trState.loadedOnce &&
                      recentTrainings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (recentTrainings.isEmpty)
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
                        itemCount: recentTrainings.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final t = recentTrainings[i];
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
