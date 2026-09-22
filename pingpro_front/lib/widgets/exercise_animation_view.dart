// Animación 3D de un ejercicio, dentro de un recuadro con esquinas.
//
// Traduce la secuencia a animaciones (buildGlbStepsForExercise) y las
// reproduce con ExerciseGlbSequenceView. Mientras carga enseña un indicador, y
// si el archivo de animaciones no se encuentra o falla al cargar, un aviso.
//
// La usan el detalle de un ejercicio y la vista previa al crearlo. Solo mira la
// secuencia, así que sirve igual para un ejercicio que todavía no existe en el
// backend.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_glb_sequence_view.dart';

class ExerciseAnimationView extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseAnimationView({super.key, required this.exercise});

  @override
  State<ExerciseAnimationView> createState() => _ExerciseAnimationViewState();
}

class _ExerciseAnimationViewState extends State<ExerciseAnimationView> {
  // Se calcula una vez: rehacerlo en cada build volvería a cargar el catálogo
  // de modelos y reiniciaría la animación.
  late final Future<List<GlbStep>> _steps = buildGlbStepsForExercise(widget.exercise);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: AppColors.widgetGrayBackground,
          child: SizedBox.expand(
            child: FutureBuilder<List<GlbStep>>(future: _steps, builder: _buildContent),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<List<GlbStep>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final steps = snap.data;
    if (snap.hasError) {
      if (kDebugMode) debugPrint('PingPro 3D: ${snap.error}');
    }
    if (snap.hasError || steps == null || steps.isEmpty) {
      return const Center(
        child: Text(
          'No hay animaciones 3D disponibles para este ejercicio',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ExerciseGlbSequenceView(steps: steps);
  }
}
