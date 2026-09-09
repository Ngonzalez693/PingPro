/// Pestaña 3: creación de ejercicios y entrenamientos.
///
/// ESTADO: es una maqueta, no una función terminada. Toda la interfaz existe
/// (pestañas, mesa, campo de nombre, categoría, duración, lista de ejercicios)
/// pero NADA se guarda: no hay ninguna llamada POST en este archivo ni en
/// pingpro_create_sequence_screen.dart.
///
/// Lo que falta para cerrarla:
///   - _pickTrainingImage, _onEditTrainingName y _onAddExerciseToTraining son
///     stubs vacíos.
///   - La mesa (PingPongTable) se pinta pero sus botones no capturan la
///     secuencia; el paso siguiente solo navega a /createSequence.
///   - No existe POST /api/exercises ni POST /api/trainings desde la app.
///   - `image` en el modelo es una ruta de asset de Flutter, así que un
///     ejercicio creado por el usuario no puede tener imagen propia sin
///     cambiar antes ese campo a URL.
///
/// Es el hueco funcional más grande de cara a publicar en tiendas: la pantalla
/// de bienvenida promete "crea tus propios ejercicios".
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/pingpong_table.dart';

enum CreateType { exercises, trainings }

class PingproCreateScreen extends StatefulWidget {
  const PingproCreateScreen({super.key});

  @override
  State<PingproCreateScreen> createState() => _PingproCreateScreenState();
}

class _PingproCreateScreenState extends State<PingproCreateScreen> {
  CreateType _selectedType = CreateType.exercises;
  final TextEditingController _nameController = TextEditingController();

  final _exService = ExercisesService();

  final String _selectedTrainingImage = 'assets/images/training_1.jpg';
  final List<ExerciseModel> _addedExercises = [];
  late List<ExerciseModel> _allExercises = [];
  String _selectedCategory = 'Grado';

  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _allExercises = await _exService.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  // Stubs sin implementar — ver la nota de estado en la cabecera del archivo.
  void _pickTrainingImage() {
    /* showModalBottomSheet as before */
  }
  void _onEditTrainingName() {
    /* optional */
  }
  void _onAddExerciseToTraining() async {
    /* push exercises screen and add */
  }
  void _onRemoveExerciseFromTraining(ExerciseModel ex) {
    setState(() => _addedExercises.remove(ex));
  }

  void _onTypeSelected(CreateType type) {
    setState(() => _selectedType = type);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Header con tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab('Ejercicios', CreateType.exercises),
                  ),
                  Expanded(
                    child: _buildTab('Entrenamientos', CreateType.trainings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (_selectedType == CreateType.exercises) ...[
              // Mesa de ping pong con botones
              Expanded(child: Center(child: const PingPongTable())),

              const SizedBox(height: 40),

              // Campo de nombre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyles.paragraph,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Nombrar ejercicio',
                      hintStyle: TextStyles.paragraph,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón continuar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/createSequence');
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.textGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ] else ...[
              // Vista para entrenamientos
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  children: [
                    // Imagen e info en fila
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen seleccionable
                        GestureDetector(
                          onTap: _pickTrainingImage,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(_selectedTrainingImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Info del entrenamiento
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      style: TextStyles.title,
                                      decoration: const InputDecoration(
                                        hintText: 'Nombre',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _onEditTrainingName,
                                    child: Text(
                                      'Editar',
                                      style: TextStyles.buttons,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Selector de categoría
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                items:
                                    ['Grado', 'Objetivo', 'Momento', 'Estilo', 'Estructura']
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              style: TextStyles.paragraphBlack,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.widgetGrayBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedCategory = v);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              // Campo de tiempo
                              TextField(
                                style: TextStyles.paragraphBlack,
                                decoration: InputDecoration(
                                  hintText: 'Tiempo (min)',
                                  filled: true,
                                  fillColor: AppColors.widgetGrayBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botón agregar ejercicio
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.textBlack,
                          size: 20,
                        ),
                        label: Text(
                          'Agregar ejercicio',
                          style: TextStyles.buttons,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: _onAddExerciseToTraining,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ejercicios agregados
                    if (_addedExercises.isNotEmpty) ...[
                      Text('Ejercicios', style: TextStyles.subTitle),
                      const SizedBox(height: 8),
                      for (var ex in _addedExercises)
                        ListTile(
                          leading: ExerciseCard(
                            exercise: ex,
                            onFavoritePressed: () {},
                          ),
                          title: Text(ex.name, style: TextStyles.paragraph),
                          trailing: TextButton(
                            onPressed: () => _onRemoveExerciseFromTraining(ex),
                            child: Text('Eliminar', style: TextStyles.buttons),
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),

                    // Recomendaciones
                    Text('Ejercicios recomendados', style: TextStyles.subTitle),
                    const SizedBox(height: 8),
                    for (var ex in _allExercises.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          onFavoritePressed:
                              () => setState(
                                () => ex.isFavorite = !ex.isFavorite,
                              ),
                          onViewPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PingproExerciseDetailScreen(
                                      exercise: ex,
                                      returnRoute: '/create',
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, CreateType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeSelected(type),
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
