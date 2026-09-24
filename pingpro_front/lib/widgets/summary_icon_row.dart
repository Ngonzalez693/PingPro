// Los tres contadores de la pantalla de Estadísticas, actuando además como
// selector: tocar uno cambia qué serie muestra la gráfica de barras.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/stat_type.dart';
import 'package:pingpro_front/widgets/summary_icon.dart';

class SummaryIconRow extends StatelessWidget {
  final StatType active;
  final void Function(StatType) onSelected;
  final int exercisesCount;
  final int trainingsCount;
  final int createdCount;

  const SummaryIconRow({
    super.key,
    required this.active,
    required this.onSelected,
    required this.exercisesCount,
    required this.trainingsCount,
    required this.createdCount,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon(StatType type, String off, String on, String label, int count) {
      return GestureDetector(
        onTap: () => onSelected(type),
        child: SummaryIcon(
          assetPath: active == type ? on : off,
          count: count,
          label: label,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          icon(StatType.exercises,
              'assets/icons/exercise_unselected.svg',
              'assets/icons/exercise_selected.svg',
              'Ejercicios',
              exercisesCount),
          icon(StatType.trainings,
              'assets/icons/training_unselected.svg',
              'assets/icons/training_selected.svg',
              'Entrenamientos',
              trainingsCount),
          icon(StatType.created,
              'assets/icons/create_unselected.svg',
              'assets/icons/create_selected.svg',
              'Creados',
              createdCount),
        ],
      ),
    );
  }
}
