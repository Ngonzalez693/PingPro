// Detalle de un entrenamiento: progreso, siguiente ejercicio y lista completa.
//
// El entrenamiento solo guarda `exerciseIds`, así que los ejercicios se
// resuelven aquí contra ExercisesState.getById(). Efecto secundario útil:
// completar un ejercicio desde su detalle actualiza esta barra de progreso al
// volver, sin recargar nada.
//
// El entrenamiento se marca como completado solo cuando TODOS sus ejercicios
// lo están. Esa comprobación ocurre dentro del build, de ahí las dos guardas:
// `_completionPosted` para no enviar la petición más de una vez, y
// addPostFrameCallback para no modificar estado en mitad del build.
//
// Lee siempre la versión viva del entrenamiento en el store: tras editarlo se
// ve la nueva. El menú ⋮ (dueño o, en el catálogo, admin) abre la edición o lo
// elimina; mientras se elimina, las acciones quedan bloqueadas.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/session_roles.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/screens/pingpro_edit_training_screen.dart';
import 'package:pingpro_front/widgets/confirm_delete_dialog.dart';
import 'package:pingpro_front/widgets/content_actions_menu.dart';

class PingproTrainingDetailScreen extends StatefulWidget {
  final TrainingModel training;

  const PingproTrainingDetailScreen({super.key, required this.training});

  @override
  State<PingproTrainingDetailScreen> createState() =>
      _PingproTrainingDetailScreenState();
}

class _PingproTrainingDetailScreenState
    extends State<PingproTrainingDetailScreen> {
  int _currentIndex = 0;

  // Para evitar llamar setCompleted durante build varias veces
  bool _completionPosted = false;

  bool _isAdmin = false;
  bool _actionLoading = false;

  // Última versión vista en el store: si el entrenamiento se elimina, la
  // pantalla sigue enseñando esta (no la de antes de editarlo) hasta cerrarse.
  TrainingModel? _lastLive;

  // Mapeo de categorías completas
  final Map<String, String> _categoryDescriptions = const {
    'Grado': 'Por grado de oposición',
    'Objetivo': 'Por objetivo técnico',
    'Momento': 'Por el momento del juego',
    'Estilo': 'Por estilo de juego',
    'Estructura': 'Por estructura del ejercicio',
  };

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
    TrainingsState.instance.load();
    SessionRoles.instance.isAdmin().then((isAdmin) {
      if (mounted) setState(() => _isAdmin = isAdmin);
    });
  }

  void _onBackPressed() => Navigator.pop(context);

  // Ir al primer ejercicio incompleto
  void _onNextPressed(List<ExerciseModel> list) {
    if (_actionLoading || list.isEmpty) return;
    final nextIdx = list.indexWhere((e) => e.completedAt == null);
    if (nextIdx == -1) return; // todos hechos

    final exerciseToShow = list[nextIdx];
    Navigator.pushNamed(
      context,
      '/exerciseDetail',
      arguments: {'exercise': exerciseToShow, 'returnRoute': '/trainings'},
    );

    setState(() {
      _currentIndex = (nextIdx < list.length - 1) ? nextIdx + 1 : nextIdx;
    });
  }

  void _onEditPressed(TrainingModel training) {
    if (_actionLoading) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => PingproEditTrainingScreen(training: training)));
  }

  Future<void> _onDeletePressed(TrainingModel training) async {
    if (_actionLoading) return;
    final confirmed = await confirmDelete(context, message: '¿Eliminar «${training.name}»?');
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _actionLoading = true);
    try {
      await TrainingsState.instance.delete(training);
      messenger.showSnackBar(const SnackBar(content: Text('Entrenamiento eliminado')));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ExercisesState.instance, TrainingsState.instance]),
          builder: (context, _) {
            final exState = ExercisesState.instance;
            final trState = TrainingsState.instance;
            final live = trState.getById(widget.training.id);
            if (live != null) _lastLive = live;
            final training = live ?? _lastLive ?? widget.training;
            final exerciseIds = training.exerciseIds;

            // Ejercicios del training desde el store
            // whereType descarta los ids que no estén en el store: un ejercicio
            // borrado no rompe la pantalla, simplemente no aparece en la lista.
            final List<ExerciseModel> exercises = exerciseIds
                .map((id) => exState.getById(id))
                .whereType<ExerciseModel>()
                .toList();

            // Carga/errores iniciales
            if (exState.isLoading && !exState.loadedOnce && exercises.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (exState.error != null && exercises.isEmpty) {
              return Center(child: Text('Error: ${exState.error}'));
            }

            // Progreso
            final total = exercises.length;
            final doneCount = exercises.where((e) => e.completedAt != null).length;
            final progress = total == 0 ? 0.0 : doneCount / total;

            // Marcar training como completado (post-frame, una sola vez)
            final alreadyCompleted = training.completedAt != null;

            if (total > 0 && doneCount == total && !alreadyCompleted && !_completionPosted) {
              _completionPosted = true; // evita múltiples posts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                TrainingsState.instance.setCompleted(training.id, true);
              });
            }

            // Duración por ejercicio: se reparte entre TODOS los ids guardados,
            // no solo los que siguen existiendo, la misma regla que usa el
            // formulario al editar (si no, un ejercicio borrado cambia el
            // número mostrado aquí y en el formulario).
            final totalDuration = training.duration;
            final exerciseCount = training.exerciseIds.length;
            final perExercise =
                exerciseCount > 0 ? (totalDuration / exerciseCount).round() : totalDuration;

            // Siguiente sugerido: primer incompleto; si no hay, null
            final nextIdx = exercises.indexWhere((e) => e.completedAt == null);
            final next = nextIdx == -1
                ? (exercises.isNotEmpty
                    ? exercises[_currentIndex.clamp(0, exercises.length - 1)]
                    : null)
                : exercises[nextIdx];

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                        onPressed: _onBackPressed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(training.name, style: TextStyles.title),
                      ),
                      if (canManage(isOwn: training.isOwn, isAdmin: _isAdmin))
                        ContentActionsMenu(
                          onEdit: () => _onEditPressed(training),
                          onDelete: () => _onDeletePressed(training),
                        ),
                    ],
                  ),
                ),

                // Cuadro superior con info + PROGRESO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.widgetBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Descripción del Entrenamiento',
                            style: TextStyles.titleBlack),
                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                training.description,
                                style: TextStyles.paragraphBlack,
                              ),
                            ),

                            const SizedBox(width: 16),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría:', style: TextStyles.buttons),
                                Text(
                                  _categoryDescriptions[training.category] ?? training.category,
                                  style: TextStyles.paragraphBlack,
                                ),

                                const SizedBox(height: 8),

                                Text('Duración:', style: TextStyles.buttons),
                                Text(
                                  '$totalDuration min ($perExercise min por ejercicio)',
                                  style: TextStyles.paragraphBlack,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ---- Barra de progreso ----
                        Text('Progreso del entrenamiento',
                            style: TextStyles.subTitleBlack),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: AppColors.widgetGrayBackground,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '$doneCount de $total ejercicios completados',
                          style: TextStyles.paragraphBlack,
                        ),

                        const SizedBox(height: 16),

                        // Recuadro del siguiente ejercicio y botón
                        if (next != null)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.widgetGrayBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    next.name,
                                    style: TextStyles.subTitleBlack,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),
                              
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _onNextPressed(exercises),
                                child: Text(
                                  nextIdx == -1 ? 'Completado' : 'Realizar siguiente',
                                  style: TextStyles.buttons,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ejercicios', style: TextStyles.subTitle),
                  ),
                ),

                const SizedBox(height: 8),

                // Lista de ExerciseCard
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = exercises[i];
                      final done = ex.completedAt != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          showTopDivider: i != 0,
                          onFavoritePressed: () =>
                              ExercisesState.instance.toggleFavorite(ex.id),
                          onViewPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/exerciseDetail',
                              arguments: {
                                'exercise': ex,
                                'returnRoute': '/trainings',
                              },
                            );
                          },
                          done: done,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
