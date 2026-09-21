// Hoja inferior para elegir un ejercicio y añadirlo a un entrenamiento.
//
// Lista todo lo que el usuario puede ver: sus ejercicios primero, marcados como
// "Propio", y después los del catálogo. Es la misma regla que aplica el backend
// al guardar: un entrenamiento propio puede mezclar ambos.
//
// Con `catalogOnly` (un admin creando un entrenamiento del catálogo) solo salen
// los del catálogo: el backend rechaza que uno del catálogo use ejercicios
// privados, porque para el resto de usuarios no existirían.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';

/// Abre la hoja. Devuelve el ejercicio elegido, o null si se cierra sin elegir.
Future<ExerciseModel?> showExercisePicker(BuildContext context, {bool catalogOnly = false}) {
  return showModalBottomSheet<ExerciseModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.tab,
    builder: (_) => ExercisePickerSheet(catalogOnly: catalogOnly),
  );
}

class ExercisePickerSheet extends StatefulWidget {
  final bool catalogOnly;

  const ExercisePickerSheet({super.key, this.catalogOnly = false});

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  @override
  void initState() {
    super.initState();
    // Idempotente: si la lista ya está cargada no pide nada.
    ExercisesState.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: AnimatedBuilder(
        animation: ExercisesState.instance,
        builder: (context, _) => _buildList(ExercisesState.instance.all),
      ),
    );
  }

  Widget _buildList(List<ExerciseModel> all) {
    if (all.isEmpty) {
      return const Center(child: Text('No hay ejercicios disponibles', style: TextStyles.paragraph));
    }
    final own = widget.catalogOnly ? <ExerciseModel>[] : all.where((e) => e.isOwn).toList();
    final catalog = all.where((e) => !e.isOwn).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (own.isNotEmpty) ...[
          _buildHeader('Tus ejercicios'),
          for (final e in own) _buildTile(e),
        ],
        _buildHeader('Catálogo'),
        for (final e in catalog) _buildTile(e),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(title, style: TextStyles.subTitle),
    );
  }

  Widget _buildTile(ExerciseModel exercise) {
    return ListTile(
      title: Text(exercise.name, style: TextStyles.paragraph),
      subtitle: Text(exercise.category, style: const TextStyle(color: AppColors.textGray)),
      trailing: exercise.isOwn
          ? const Chip(label: Text('Propio'), backgroundColor: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(context, exercise),
    );
  }
}
