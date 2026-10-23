// Animación 3D de un ejercicio, dentro de un recuadro con esquinas.
//
// Traduce la secuencia a animaciones (buildGlbStepsForExercise) y las
// reproduce con ExerciseSequenceViewer. Mientras carga enseña un indicador; si
// no se pudo averiguar dónde está el archivo (sin red y sin URL recordada), el
// aviso amable con "Reintentar"; y si no hay archivo de animaciones, un aviso.
//
// La usan el detalle de un ejercicio y la vista previa al crearlo. Solo mira la
// secuencia, así que sirve igual para un ejercicio que todavía no existe en el
// backend.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_sequence_viewer.dart';
import 'package:pingpro_front/widgets/load_error_view.dart';

class ExerciseAnimationView extends StatefulWidget {
  final ExerciseModel exercise;
  final Future<List<GlbStep>> Function(ExerciseModel exercise) _buildSteps;

  const ExerciseAnimationView({
    super.key,
    required this.exercise,
    @visibleForTesting Future<List<GlbStep>> Function(ExerciseModel exercise)? buildSteps,
  }) : _buildSteps = buildSteps ?? buildGlbStepsForExercise;

  @override
  State<ExerciseAnimationView> createState() => _ExerciseAnimationViewState();
}

class _ExerciseAnimationViewState extends State<ExerciseAnimationView> {
  // Se calcula una vez (y otra con "Reintentar"): rehacerlo en cada build
  // volvería a cargar el catálogo de modelos y reiniciaría la animación.
  late Future<List<GlbStep>> _steps = _load();

  // ignore(): el error lo muestra el FutureBuilder, que empieza a escuchar en
  // el siguiente fotograma; sin esto, si llega antes, Dart lo da por perdido.
  Future<List<GlbStep>> _load() => widget._buildSteps(widget.exercise)..ignore();

  void _retry() {
    setState(() {
      _steps = _load();
    });
  }

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
    if (snap.error case final error?) {
      if (kDebugMode) debugPrint('PingPro 3D: $error');
      return LoadErrorView(message: loadErrorMessage(error), onRetry: _retry);
    }
    final steps = snap.data;
    if (steps == null || steps.isEmpty) {
      return const Center(
        child: Text(
          'No hay animaciones 3D disponibles para este ejercicio',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ExerciseSequenceViewer(steps: steps);
  }
}
