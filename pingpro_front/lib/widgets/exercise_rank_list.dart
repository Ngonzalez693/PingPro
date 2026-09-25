// Lista corta de ejercicios con una etiqueta a la derecha (×N, "hace N
// días"...). Tocar uno lo abre; qué hacer lo decide la pantalla.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';

class ExerciseRankList extends StatelessWidget {
  final String title;
  final List<(ExerciseModel, String)> rows;
  final String emptyText;
  final ValueChanged<ExerciseModel> onTap;

  const ExerciseRankList({
    super.key,
    required this.title,
    required this.rows,
    required this.emptyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.subTitleBlack),
          const SizedBox(height: 8),
          if (rows.isEmpty) Text(emptyText, style: TextStyles.aditional),
          for (final row in rows) _buildRow(row.$1, row.$2),
        ],
      ),
    );
  }

  Widget _buildRow(ExerciseModel exercise, String trailing) {
    return InkWell(
      onTap: () => onTap(exercise),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(exercise.name, style: TextStyles.paragraphBlack, overflow: TextOverflow.ellipsis),
            ),
            Text(trailing, style: TextStyles.aditional),
          ],
        ),
      ),
    );
  }
}
