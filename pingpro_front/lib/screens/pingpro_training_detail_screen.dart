import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';

class PingproTrainingDetailScreen extends StatefulWidget {
  final TrainingModel training;

  const PingproTrainingDetailScreen({
    super.key,
    required this.training,
  });

  @override
  State<PingproTrainingDetailScreen> createState() =>
      _PingproTrainingDetailScreenState();
}

class _PingproTrainingDetailScreenState
    extends State<PingproTrainingDetailScreen> {
  // Lista de ejercicios del entrenamiento
  List<ExerciseModel> _exercises = [];
  // Índice del siguiente ejercicio a realizar
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  // Carga los ExerciseModel cuyo id esté en training.exerciseIds
  Future<void> _loadExercises() async {
    final all = await ExercisesService().fetchAll();
    setState(() {
      _exercises = all
          .where((ex) => widget.training.exerciseIds.contains(ex.id))
          .toList();
    });
  }

  // Al presionar "Realizar siguiente"
  void _onNextPressed() {
    // Si hay al menos un ejercicio
    if (_exercises.isNotEmpty) {
      // Navega al ejercicio actual
      final exerciseToShow = _exercises[_currentIndex];
      Navigator.pushNamed(
        context,
        '/exerciseDetail',
        arguments: {
          'exercise': exerciseToShow,
          'returnRoute': '/trainings',
        },
      );
      // Luego incrementa el índice para la próxima vez
      if (_currentIndex < _exercises.length - 1) {
        setState(() => _currentIndex++);
      }
    }
  }

  // Volver atrás
  void _onBackPressed() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    // Cálculo de duración por ejercicio
    final totalDuration = widget.training.duration;
    final count = _exercises.length;
    final perExercise =
        count > 0 ? (totalDuration / count).round() : totalDuration;

    // Siguiente ejercicio a mostrar en el recuadro
    final next = _exercises.isNotEmpty ? _exercises[_currentIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ► Header con flecha y nombre del entrenamiento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textWhite),
                    onPressed: _onBackPressed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.training.name,
                      style: TextStyles.title,
                    ),
                  ),
                ],
              ),
            ),

            // ► Cuadro superior con descripción y datos del entrenamiento
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
                            Text(widget.training.category,
                                style: TextStyles.paragraphBlack),
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
                    // ► Recuadro del siguiente ejercicio y botón
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
                            onPressed: _onNextPressed,
                            child:
                                const Text('Realizar siguiente', style: TextStyles.buttons),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ► Título "Ejercicios"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ejercicios', style: TextStyles.subTitle),
              ),
            ),

            const SizedBox(height: 8),

            // ► Lista de ExerciseCard
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exercises.length,
                itemBuilder: (ctx, i) {
                  final ex = _exercises[i];
                  final done = i < _currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExerciseCard(
                      exercise: ex,
                      showTopDivider: i != 0,
                      onFavoritePressed: () =>
                          setState(() => ex.isFavorite = !ex.isFavorite),
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
        ),
      ),
    );
  }
}
