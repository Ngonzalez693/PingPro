// Pestaña 3: creación de ejercicios y entrenamientos propios.
//
// Solo elige qué se crea. Cada formulario vive en su widget:
//   - widgets/create_exercise_form.dart
//   - widgets/create_training_form.dart
// Lo creado aquí es privado: solo lo ve quien lo crea.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/create_exercise_form.dart';
import 'package:pingpro_front/widgets/create_training_form.dart';

enum CreateType { exercises, trainings }

class PingproCreateScreen extends StatefulWidget {
  const PingproCreateScreen({super.key});

  @override
  State<PingproCreateScreen> createState() => _PingproCreateScreenState();
}

class _PingproCreateScreenState extends State<PingproCreateScreen> {
  CreateType _selectedType = CreateType.exercises;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(child: _buildTab('Ejercicios', CreateType.exercises)),
                  Expanded(child: _buildTab('Entrenamientos', CreateType.trainings)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // IndexedStack y no un if: cambiar de pestaña no borra lo que ya se
            // había escrito en el otro formulario.
            Expanded(
              child: IndexedStack(
                index: _selectedType.index,
                children: const [CreateExerciseForm(), CreateTrainingForm()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, CreateType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.paragraph.copyWith(
              color: selected ? AppColors.textWhite : AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: selected ? AppColors.primary : AppColors.secundary,
          ),
        ],
      ),
    );
  }
}
