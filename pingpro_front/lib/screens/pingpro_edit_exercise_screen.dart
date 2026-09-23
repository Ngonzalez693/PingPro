// Editar un ejercicio: el mismo formulario de crear, relleno con sus datos.
//
// Se abre desde el menú ⋮ del detalle. Al guardar, el formulario cierra esta
// pantalla y el detalle muestra la versión nueva.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/create_exercise_form.dart';

class PingproEditExerciseScreen extends StatelessWidget {
  final ExerciseModel exercise;

  const PingproEditExerciseScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(child: Text('Editar ejercicio', style: TextStyles.title)),
              ],
            ),
            Expanded(child: CreateExerciseForm(initial: exercise)),
          ],
        ),
      ),
    );
  }
}
