import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_done.dart';

class PingproExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final String returnRoute;

  const PingproExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.returnRoute,
  });

  @override
  State<PingproExerciseDetailScreen> createState() =>
      _PingproExerciseDetailScreenState();
}

class _PingproExerciseDetailScreenState
    extends State<PingproExerciseDetailScreen> {
  late bool _isFavorite;

  // Maping
  final Map<int, String> _hits = {
    1: 'Forehand',
    2: 'Backhand',
    3: 'Forehand/Backhand',
    4: 'Forehand Flick',
    5: 'Banana Flick',
    6: 'Strawberry Flick',
    7: 'Servicio',
    8: 'Libre',
    9: 'Hasta que se caiga',
  };

  final Map<int, String> _rotations = {
    1: 'Back Spin',
    2: 'Topspin',
    3: 'Side Spin Derecha',
    4: 'Side Spin Izquierda',
    5: 'Drive',
    6: 'Liftado',
    7: 'Libre',
  };

  final Map<int, String> _zones = {
    1: 'Corto',
    2: 'Intermedio',
    3: 'Largo',
    4: 'Libre',
  };

  final Map<int, String> _directions = {
    1: 'Lateral Derecho',
    2: 'Esquina Derecha',
    3: 'Medio Derecha',
    4: 'Medio',
    5: 'Medio Izquierdo',
    6: 'Esquina Izquierda',
    7: 'Lateral Izquierda',
    8: 'Libre',
  };

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.exercise.isFavorite;
  }

  // Contrucción de la descripción
  String _buildSequenceDescription() {
    final sequence = widget.exercise.sequence;
    final List<String> steps = [];

    for (int i = 0; i < sequence.length; i++) {
      final step = sequence[i];
      final stepNumber = i + 1;

      // Golpe en descripción
      String hit;
      if (step.hit == 1 && (step.side == 4 || step.side == 5)) {
        hit = 'Forehand Pivot';
      } else {
        hit = _hits[step.hit] ?? 'Desconocido';
      }

      // Rotación en descripción
      final rotation = _rotations[step.rotation] ?? 'Desconocido';
      // Zona en descripción
      final zone = _zones[step.zone] ?? 'Desconocido';
      // Dirección en descripción
      final direction = _directions[step.direction] ?? 'Desconocido';

      steps.add('$stepNumber. $hit $rotation $zone a $direction');
    }

    return steps.join('\n');
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  void _onFavoritePressed() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Actualizar en el servicio/backend
  }

  void _onDonePressed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ExerciseDone(
            onFinalize: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de regreso y nombre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onBackPressed,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.exercise.name, style: TextStyles.title),
                  ),
                ],
              ),
            ),

            // Área para el widget 3D (placeholder por ahora)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.widgetGrayBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Widget 3D del Ejercicio\n(En desarrollo)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGray, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Sección inferior con descripción y botones
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Descripción paso a paso
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descripción del ejercicio',
                                  style: TextStyles.subTitle,
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.exercise.description,
                                          style: TextStyles.paragraph,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Pasos:',
                                          style: TextStyles.subTitle,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _buildSequenceDescription(),
                                          style: TextStyles.paragraph.copyWith(
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Botones
                    Column(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly, // Empuja hacia abajo
                      children: [
                        // Botón favorito
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.widgetGrayBackground,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _onFavoritePressed,
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botón "Hecho"
                        GestureDetector(
                          onTap: _onDonePressed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Hecho', style: TextStyles.buttons),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
