// Creación de ejercicios y entrenamientos.
//
// Solo elige qué se crea. Cada formulario vive en su widget:
//   - widgets/create_exercise_form.dart
//   - widgets/create_training_form.dart
//
// Se usa de dos formas, según `scope`:
//   - own: la pestaña 3 de la barra inferior. Lo creado es privado.
//   - catalog: el acceso de admin desde el perfil. Lo creado va al catálogo y
//     lo ve todo el mundo; se abre encima del perfil, con flecha para volver.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/widgets/create_exercise_form.dart';
import 'package:pingpro_front/widgets/create_training_form.dart';

enum CreateType { exercises, trainings }

class PingproCreateScreen extends StatefulWidget {
  final ContentScope scope;

  const PingproCreateScreen({super.key, this.scope = ContentScope.own});

  @override
  State<PingproCreateScreen> createState() => _PingproCreateScreenState();
}

class _PingproCreateScreenState extends State<PingproCreateScreen> {
  CreateType _selectedType = CreateType.exercises;

  bool get _isCatalog => widget.scope == ContentScope.catalog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _isCatalog ? _buildCatalogHeader() : const SizedBox(height: 40),
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
                children: [
                  CreateExerciseForm(scope: widget.scope),
                  CreateTrainingForm(scope: widget.scope),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(child: Text('Crear para el catálogo', style: TextStyles.title)),
        ],
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
