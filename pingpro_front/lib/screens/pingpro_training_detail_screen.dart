import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';

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
  }

  void _onBackPressed() => Navigator.pop(context);

  // Al presionar "Realizar siguiente": navega al ejercicio actual y avanza el índice
  void _onNextPressed(List<ExerciseModel> list) {
    if (list.isEmpty) return;

    // Aseguramos que el índice no se pase si cambia la lista
    final idx = _currentIndex.clamp(0, list.length - 1);
    final exerciseToShow = list[idx];

    Navigator.pushNamed(
      context,
      '/exerciseDetail',
      arguments: {'exercise': exerciseToShow, 'returnRoute': '/trainings'},
    );

    if (idx < list.length - 1) {
      setState(() => _currentIndex = idx + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseIds = widget.training.exerciseIds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ExercisesState.instance,
          builder: (context, _) {
            final s = ExercisesState.instance;

            final List<ExerciseModel> exercises = exerciseIds
                .map((id) => s.getById(id))
                .whereType<ExerciseModel>()
                .toList();

            // Cálculo de duración por ejercicio
            final totalDuration = widget.training.duration;
            final count = exercises.length;
            final perExercise =
                count > 0 ? (totalDuration / count).round() : totalDuration;

            // Siguiente ejercicio a mostrar
            final hasNext = exercises.isNotEmpty;
            final safeIndex =
                hasNext ? _currentIndex.clamp(0, exercises.length - 1) : 0;
            final next = hasNext ? exercises[safeIndex] : null;

            // Estados de carga/errores del store (solo si aún no hay nada)
            if (s.isLoading && !s.loadedOnce && exercises.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.error != null && exercises.isEmpty) {
              return Center(child: Text('Error: ${s.error}'));
            }

            return Column(
              children: [
                // Header con flecha y nombre del entrenamiento
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textWhite,
                        ),
                        onPressed: _onBackPressed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.training.name, style: TextStyles.title),
                      ),
                    ],
                  ),
                ),

                // Cuadro superior con descripción y datos del entrenamiento
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
                        // "Descripción del Entrenamiento"
                        Text(
                          'Descripción del Entrenamiento',
                          style: TextStyles.titleBlack,
                        ),

                        const SizedBox(height: 8),

                        // Descripción, categoría y duración
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Descripción amplia
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.training.description,
                                style: TextStyles.paragraphBlack,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Datos extra: categoría y duración
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
                                child: const Text(
                                  'Realizar siguiente',
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
                      final done = i < _currentIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          showTopDivider: i != 0,
                          // Favorito sincronizado con otras pantallas
                          onFavoritePressed: () =>
                              ExercisesState.instance.toggleFavorite(ex.id),
                          // Navegación al detalle (completed se maneja allá)
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
