// Formulario para crear un entrenamiento propio: la pestaña "Entrenamientos"
// de Crear.
//
// Un entrenamiento es una lista ordenada de ejercicios. Se añaden desde una
// hoja con los del catálogo y los propios, se pueden reordenar arrastrando y
// quitar, y un mismo ejercicio puede aparecer más de una vez.
//
// El tiempo se pide por ejercicio; la duración total (la que guarda el
// backend) sale de multiplicarlo por la cantidad de ejercicios.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/form_styles.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/training_options.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_draft_model.dart';
import 'package:pingpro_front/widgets/exercise_picker_sheet.dart';
import 'package:pingpro_front/widgets/image_option_picker.dart';

// Cada entrada lleva su propia clave: el mismo ejercicio puede repetirse, y la
// lista reordenable necesita distinguir las dos apariciones.
typedef _Entry = ({int key, ExerciseModel exercise});

class CreateTrainingForm extends StatefulWidget {
  /// A dónde va el entrenamiento: lo propio del usuario o el catálogo (admin).
  final ContentScope scope;

  const CreateTrainingForm({super.key, this.scope = ContentScope.own});

  @override
  State<CreateTrainingForm> createState() => _CreateTrainingFormState();
}

class _CreateTrainingFormState extends State<CreateTrainingForm> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _minutes = TextEditingController();
  String _category = trainingCategories.first;
  String _image = trainingImages.first;
  List<_Entry> _entries = const [];
  int _nextKey = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Para activar "Crear" y recalcular la duración total al escribir.
    _name.addListener(_refresh);
    _minutes.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _minutes.dispose();
    super.dispose();
  }

  int? get _minutesPerExercise {
    final minutes = int.tryParse(_minutes.text);
    return minutes != null && minutes > 0 ? minutes : null;
  }

  bool get _canCreate =>
      !_saving && _name.text.trim().isNotEmpty && _entries.isNotEmpty && _minutesPerExercise != null;

  // Al cerrarse una ruta, Flutter devuelve el foco al campo que lo tenía al
  // abrirla, y con él vuelve el teclado. Soltar el foco antes de navegar evita
  // que aparezca al volver del selector o del detalle.
  void _dropFocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _addExercise() async {
    _dropFocus();
    final exercise = await showExercisePicker(context, catalogOnly: widget.scope == ContentScope.catalog);
    if (exercise == null || !mounted) return;
    setState(() => _entries = [..._entries, (key: _nextKey++, exercise: exercise)]);
  }

  void _removeAt(int index) => setState(() => _entries = [..._entries]..removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    // ReorderableListView da el destino contando todavía el elemento movido.
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    setState(() {
      final entries = [..._entries];
      entries.insert(target, entries.removeAt(oldIndex));
      _entries = entries;
    });
  }

  Future<void> _create() async {
    final draft = TrainingDraft(
      name: _name.text,
      category: _category,
      image: _image,
      description: _description.text,
      exerciseIds: [for (final e in _entries) e.exercise.id],
      minutesPerExercise: _minutesPerExercise!,
      scope: widget.scope,
    );
    _dropFocus();
    setState(() => _saving = true);
    try {
      final id = await TrainingsState.instance.create(draft);
      if (!mounted) return;
      _reset();
      _showMessage('Entrenamiento creado');
      _openDetail(id);
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Abre el detalle del entrenamiento recién creado para verlo tal como quedó.
  // Si la recarga de la lista no lo trajo (p. ej. falló la red justo después
  // de crear), se queda en el formulario: el aviso de creado ya salió.
  void _openDetail(String id) {
    final training = TrainingsState.instance.getById(id);
    if (training == null) return;
    Navigator.pushNamed(context, '/trainingDetail', arguments: training);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _reset() {
    _name.clear();
    _description.clear();
    _minutes.clear();
    setState(() {
      _category = trainingCategories.first;
      _image = trainingImages.first;
      _entries = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      children: [
        _buildTextField(_name, 'Nombre del entrenamiento'),
        const SizedBox(height: 12),
        _buildCategory(),
        const SizedBox(height: 12),
        _buildMinutes(),
        const SizedBox(height: 12),
        _buildTextField(_description, 'Descripción (opcional)', maxLines: 3),
        const SizedBox(height: 20),
        const Text('Imagen', style: TextStyles.subTitle),
        const SizedBox(height: 8),
        ImageOptionPicker(
          images: trainingImages,
          selected: _image,
          onSelected: (path) => setState(() => _image = path),
        ),
        const SizedBox(height: 20),
        _buildExercisesHeader(),
        _buildExerciseList(),
        const SizedBox(height: 24),
        _buildCreateButton(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyles.paragraphBlack,
      decoration: formInputDecoration(hint),
    );
  }

  Widget _buildCategory() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: formInputDecoration('Categoría'),
      items: [
        for (final c in trainingCategories)
          DropdownMenuItem(value: c, child: Text(c, style: TextStyles.paragraphBlack)),
      ],
      onChanged: (c) {
        if (c != null) setState(() => _category = c);
      },
    );
  }

  Widget _buildMinutes() {
    final minutes = _minutesPerExercise;
    final total = minutes == null ? null : minutes * _entries.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _minutes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyles.paragraphBlack,
          decoration: formInputDecoration('Minutos por ejercicio'),
        ),
        if (total != null) ...[
          const SizedBox(height: 6),
          Text('Duración total: $total min', style: TextStyles.paragraph),
        ],
      ],
    );
  }

  Widget _buildExercisesHeader() {
    return Row(
      children: [
        const Expanded(child: Text('Ejercicios', style: TextStyles.subTitle)),
        TextButton.icon(
          onPressed: _addExercise,
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text('Agregar ejercicio', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Todavía no hay ejercicios', style: TextStyle(color: AppColors.textGray)),
      );
    }
    // Dentro de otro ListView: sin scroll propio y a la altura de su contenido.
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _reorder,
      children: [for (var i = 0; i < _entries.length; i++) _buildEntry(i)],
    );
  }

  Widget _buildEntry(int index) {
    final exercise = _entries[index].exercise;
    return ListTile(
      key: ValueKey(_entries[index].key),
      contentPadding: EdgeInsets.zero,
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle, color: AppColors.textGray),
      ),
      title: Text('${index + 1}. ${exercise.name}', style: TextStyles.paragraph),
      subtitle: exercise.isOwn ? const Text('Propio', style: TextStyle(color: AppColors.primary)) : null,
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textGray),
        tooltip: 'Quitar ejercicio ${index + 1}',
        onPressed: () => _removeAt(index),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
        ),
        onPressed: _canCreate ? _create : null,
        child: _saving
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Crear', style: TextStyles.buttons),
      ),
    );
  }
}
