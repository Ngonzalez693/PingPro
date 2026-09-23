// Pestaña 5: perfil con resumen de actividad e historial reciente.
//
// La actividad sale de los stores en memoria. "Recientes" se calcula ordenando
// por completedAt descendente.
//
// El nombre viene de FirebaseAuth.currentUser. La única petición propia es
// GET /api/users/me, solo para saber si el usuario es admin: a los admins se
// les enseña el acceso para crear contenido del catálogo.
//
// El bloque de la gráfica está copiado casi literalmente de
// pingpro_home_screen.dart — extraerlo a un widget compartido es el refactor
// más rentable de esta pantalla.
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
import 'package:pingpro_front/core/services/trainings_state.dart';

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

            // Conteos para resumen
            final exercisesCount = doneExercises.length;
            final trainingsCount = doneTrainings.length;
            final createdCount = 0; // ajústalo si llevas esta métrica

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
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          ExercisesState.instance,
                          TrainingsState.instance,
                        ]),
                        builder: (context, _) {
                          final es = ExercisesState.instance;
                          final ts = TrainingsState.instance;

                          // Últimos 7 días (de más viejo -> hoy)
                          final now = DateTime.now();
                          final buckets = List.generate(7, (i) {
                            final d = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ).subtract(Duration(days: 6 - i));
                            return d;
                          });

                          // Etiquetas: D L M X J V S
                          const dias = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
                          String labelFor(DateTime d) => dias[d.weekday % 7];
                          final labels = buckets.map(labelFor).toList();

                          // Fechas completadas
                          final exercisesDates =
                              es.all
                                  .where((e) => e.completedAt != null)
                                  .map((e) => e.completedAt!)
                                  .toList();

                          final trainingsDates =
                              ts.all
                                  .where((t) => t.completedAt != null)
                                  .map((t) => t.completedAt!)
                                  .toList();

                          // Si luego tienes "creados", añade sus fechas aquí
                          final createdDates = <DateTime>[];

                          bool sameDay(DateTime a, DateTime b) =>
                              a.year == b.year &&
                              a.month == b.month &&
                              a.day == b.day;

                          List<int> countSeries(List<DateTime> dates) => [
                            for (final b in buckets)
                              dates.where((d) => sameDay(d, b)).length,
                          ];

                          final exSeries = countSeries(exercisesDates);
                          final trSeries = countSeries(trainingsDates);
                          final crSeries = countSeries(createdDates);

                          // Serie total para el gráfico de líneas
                          final totalSeries = List<int>.generate(
                            buckets.length,
                            (i) => exSeries[i] + trSeries[i] + crSeries[i],
                          );

                          // Loader mínimo (opcional)
                          if ((es.isLoading && !es.loadedOnce) ||
                              (ts.isLoading && !ts.loadedOnce)) {
                            return const SizedBox(
                              height: 160,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          return StatisticsChart(
                            values: totalSeries,
                            labels: labels,
                          );
                        },
                      ),
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
