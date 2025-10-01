import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';

class PingproTrainingDetailScreen extends StatefulWidget {
  final TrainingModel training;

  const PingproTrainingDetailScreen({super.key, required this.training});

  @override
  State<PingproTrainingDetailScreen> createState() =>
      _PingproTrainingDetailScreenState();
}

class _PingproTrainingDetailScreenState
    extends State<PingproTrainingDetailScreen> {
  int _currentIndex = 0;

  // Para evitar llamar setCompleted durante build varias veces
  bool _completionPosted = false;

  // Mapeo de categorías completas
  final Map<String, String> _categoryDescriptions = const {
    'Grado': 'Por grado de oposición',
    'Objetivo': 'Por objetivo técnico',
    'Momento': 'Por el momento del juego',
    'Estilo': 'Por estilo de juego',
    'Estructura': 'Por estructura del ejercicio',
  };

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
    TrainingsState.instance.load();
  }

  void _onBackPressed() => Navigator.pop(context);

  // Ir al primer ejercicio incompleto
  void _onNextPressed(List<ExerciseModel> list) {
    if (list.isEmpty) return;
    final nextIdx = list.indexWhere((e) => e.completedAt == null);
    if (nextIdx == -1) return; // todos hechos

    final exerciseToShow = list[nextIdx];
    Navigator.pushNamed(
      context,
      '/exerciseDetail',
      arguments: {'exercise': exerciseToShow, 'returnRoute': '/trainings'},
    );

    setState(() {
      _currentIndex = (nextIdx < list.length - 1) ? nextIdx + 1 : nextIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseIds = widget.training.exerciseIds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ExercisesState.instance, TrainingsState.instance]),
          builder: (context, _) {
            final exState = ExercisesState.instance;
            final trState = TrainingsState.instance;

            // Ejercicios del training desde el store
            final List<ExerciseModel> exercises = exerciseIds
                .map((id) => exState.getById(id))
                .whereType<ExerciseModel>()
                .toList();

            // Carga/errores iniciales
            if (exState.isLoading && !exState.loadedOnce && exercises.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (exState.error != null && exercises.isEmpty) {
              return Center(child: Text('Error: ${exState.error}'));
            }

            // Progreso
            final total = exercises.length;
            final doneCount = exercises.where((e) => e.completedAt != null).length;
            final progress = total == 0 ? 0.0 : doneCount / total;

            // Marcar training como completado (post-frame, una sola vez)
            final tLive = trState.getById(widget.training.id) ?? widget.training;
            final alreadyCompleted = tLive.completedAt != null;

            if (total > 0 && doneCount == total && !alreadyCompleted && !_completionPosted) {
              _completionPosted = true; // evita múltiples posts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                TrainingsState.instance.setCompleted(widget.training.id, true);
              });
            }

            // Duración por ejercicio
            final totalDuration = widget.training.duration;
            final perExercise =
                total > 0 ? (totalDuration / total).round() : totalDuration;

            // Siguiente sugerido: primer incompleto; si no hay, null
            final nextIdx = exercises.indexWhere((e) => e.completedAt == null);
            final next = nextIdx == -1
                ? (exercises.isNotEmpty
                    ? exercises[_currentIndex.clamp(0, exercises.length - 1)]
                    : null)
                : exercises[nextIdx];

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                        onPressed: _onBackPressed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.training.name, style: TextStyles.title),
                      ),
                    ],
                  ),
                ),

                // Cuadro superior con info + PROGRESO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.widgetBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Descripción del Entrenamiento',
                            style: TextStyles.titleBlack),
                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.training.description,
                                style: TextStyles.paragraphBlack,
                              ),
                            ),

                            const SizedBox(width: 16),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría:', style: TextStyles.buttons),
                                Text(
                                  _categoryDescriptions[widget.training.category] ??
                                      widget.training.category,
                                  style: TextStyles.paragraphBlack,
                                ),

                                const SizedBox(height: 8),

                                Text('Duración:', style: TextStyles.buttons),
                                Text(
                                  '$totalDuration min ($perExercise min por ejercicio)',
                                  style: TextStyles.paragraphBlack,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ---- Barra de progreso ----
                        Text('Progreso del entrenamiento',
                            style: TextStyles.subTitleBlack),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: AppColors.widgetGrayBackground,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '$doneCount de $total ejercicios completados',
                          style: TextStyles.paragraphBlack,
                        ),

                        const SizedBox(height: 16),

                        // Recuadro del siguiente ejercicio y botón
                        if (next != null)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.widgetGrayBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    next.name,
                                    style: TextStyles.subTitleBlack,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),
                              
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _onNextPressed(exercises),
                                child: Text(
                                  nextIdx == -1 ? 'Completado' : 'Realizar siguiente',
                                  style: TextStyles.buttons,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ejercicios', style: TextStyles.subTitle),
                  ),
                ),

                const SizedBox(height: 8),

                // Lista de ExerciseCard
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = exercises[i];
                      final done = ex.completedAt != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          showTopDivider: i != 0,
                          onFavoritePressed: () =>
                              ExercisesState.instance.toggleFavorite(ex.id),
                          onViewPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/exerciseDetail',
                              arguments: {
                                'exercise': ex,
                                'returnRoute': '/trainings',
                              },
                            );
                          },
                          done: done,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
