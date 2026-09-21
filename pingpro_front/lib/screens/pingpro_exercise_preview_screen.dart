// Vista previa de un ejercicio antes de crearlo: la animación 3D y los pasos en
// texto, para comprobar que la secuencia dibujada es la que se quería.
//
// Se abre encima del editor de secuencias. "Volver a editar" cierra solo esta
// pantalla y deja el editor con sus flechas. "Crear" lo guarda en el backend y
// devuelve true, que es la señal para que el editor también se cierre.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/widgets/exercise_animation_view.dart';

class PingproExercisePreviewScreen extends StatefulWidget {
  final ExerciseDraft draft;

  const PingproExercisePreviewScreen({super.key, required this.draft});

  @override
  State<PingproExercisePreviewScreen> createState() => _PingproExercisePreviewScreenState();
}

class _PingproExercisePreviewScreenState extends State<PingproExercisePreviewScreen> {
  bool _saving = false;

  Future<void> _create() async {
    setState(() => _saving = true);
    try {
      await ExercisesState.instance.create(widget.draft);
      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.draft.toPreviewModel();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(exercise.name),
            Expanded(flex: 2, child: ExerciseAnimationView(exercise: exercise)),
            Expanded(child: _buildSteps()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: _saving ? null : () => Navigator.pop<bool>(context, false),
          ),
          Expanded(child: Text(name, style: TextStyles.title)),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    final sequence = widget.draft.sequence;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      children: [
        const Text('Pasos', style: TextStyles.subTitle),
        const SizedBox(height: 8),
        for (var i = 0; i < sequence.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${i + 1}. ${describeStep(sequence[i])}', style: TextStyles.paragraph),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
              onPressed: _saving ? null : () => Navigator.pop<bool>(context, false),
              child: const Text('Volver a editar', style: TextStyle(color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear', style: TextStyles.buttons),
            ),
          ),
        ],
      ),
    );
  }
}
