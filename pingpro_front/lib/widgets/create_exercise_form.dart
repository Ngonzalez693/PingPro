// Formulario para crear un ejercicio propio: la pestaña "Ejercicios" de Crear.
//
// El recorrido completo:
//   1. Aquí: nombre, categoría, descripción opcional e imagen.
//   2. "Siguiente" abre el editor de secuencias.
//   3. Su "Subir y ver" abre la vista previa 3D encima del editor.
//   4. "Crear" lo guarda; al volver, el formulario se vacía y avisa.
// Si en la vista previa se vuelve atrás, el editor sigue con lo dibujado.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/exercise_options.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/screens/pingpro_create_sequence_screen.dart';
import 'package:pingpro_front/screens/pingpro_exercise_preview_screen.dart';

class CreateExerciseForm extends StatefulWidget {
  const CreateExerciseForm({super.key});

  @override
  State<CreateExerciseForm> createState() => _CreateExerciseFormState();
}

class _CreateExerciseFormState extends State<CreateExerciseForm> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _category = exerciseCategories.first;
  String _image = exerciseImages.first;

  @override
  void initState() {
    super.initState();
    // Solo para activar "Siguiente" en cuanto haya nombre.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canContinue => _name.text.trim().isNotEmpty;

  Future<void> _openEditor() async {
    final created = await Navigator.push<List<SequenceStep>>(
      context,
      MaterialPageRoute(builder: (_) => PingproCreateSequenceScreen(onReview: _review)),
    );
    // El editor solo devuelve la secuencia cuando el ejercicio ya se creó.
    if (created == null || !mounted) return;
    _reset();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio creado')));
  }

  Future<bool> _review(List<SequenceStep> steps) async {
    final draft = ExerciseDraft(
      name: _name.text,
      category: _category,
      image: _image,
      description: _description.text,
      sequence: steps,
    );
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PingproExercisePreviewScreen(draft: draft)),
    );
    return created ?? false;
  }

  void _reset() {
    _name.clear();
    _description.clear();
    setState(() {
      _category = exerciseCategories.first;
      _image = exerciseImages.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      children: [
        _buildTextField(_name, 'Nombre del ejercicio'),
        const SizedBox(height: 12),
        _buildCategory(),
        const SizedBox(height: 12),
        _buildTextField(_description, 'Descripción (opcional)', maxLines: 3),
        const SizedBox(height: 20),
        const Text('Imagen', style: TextStyles.subTitle),
        const SizedBox(height: 8),
        _buildImagePicker(),
        const SizedBox(height: 28),
        _buildContinueButton(),
      ],
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.widgetGrayBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyles.paragraphBlack,
      decoration: _decoration(hint),
    );
  }

  Widget _buildCategory() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: _decoration('Categoría'),
      items: [
        for (final c in exerciseCategories)
          DropdownMenuItem(value: c, child: Text(c, style: TextStyles.paragraphBlack)),
      ],
      onChanged: (c) {
        if (c != null) setState(() => _category = c);
      },
    );
  }

  Widget _buildImagePicker() {
    return Row(
      children: [
        for (var i = 0; i < exerciseImages.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _buildImageOption(exerciseImages[i], i + 1)),
        ],
      ],
    );
  }

  Widget _buildImageOption(String path, int number) {
    final selected = path == _image;
    return Semantics(
      label: 'Imagen $number',
      selected: selected,
      button: true,
      child: GestureDetector(
        key: ValueKey(path),
        onTap: () => setState(() => _image = path),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.primary : AppColors.tab, width: 3),
              image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
        onPressed: _canContinue ? _openEditor : null,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Siguiente', style: TextStyles.buttons),
      ),
    );
  }
}
