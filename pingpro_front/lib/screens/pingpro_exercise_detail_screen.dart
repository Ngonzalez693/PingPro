// Detalle de un ejercicio: visor 3D arriba, descripción y acciones abajo.
//
// Es la pantalla donde converge todo el proyecto:
//   - ExerciseAnimationView convierte la secuencia en animaciones 3D y las
//     reproduce.
//   - _buildSequenceDescription() traduce los mismos códigos a texto legible.
//   - El botón "Hecho" es el ÚNICO sitio de la app que marca un ejercicio como
//     completado, y por tanto el que alimenta todas las estadísticas.
//   - El menú ⋮ (solo para el dueño o, en el catálogo, para un admin) abre la
//     edición o elimina el ejercicio.
//
// Lee el ejercicio "vivo" del store por id en vez de usar el que llega por
// parámetro: así el corazón y el estado de completado siguen siendo correctos
// aunque se haya modificado desde otra pantalla.
//
// Los nombres de los códigos salen de core/stroke_codes.dart, compartidos con
// el editor de secuencias.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/screens/pingpro_edit_exercise_screen.dart';
import 'package:pingpro_front/widgets/confirm_delete_dialog.dart';
import 'package:pingpro_front/widgets/content_actions_menu.dart';
import 'package:pingpro_front/widgets/exercise_done.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/session_roles.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/widgets/exercise_animation_view.dart';

class PingproExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final String returnRoute;

  const PingproExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.returnRoute,
  });

  @override
  State<PingproExerciseDetailScreen> createState() =>
      _PingproExerciseDetailScreenState();
}

class _PingproExerciseDetailScreenState
    extends State<PingproExerciseDetailScreen> {
  bool _actionLoading = false;
  bool _isAdmin = false;

  /// Última versión "viva" vista del store, para no volver a `widget.exercise`
  /// (desactualizado tras editar) mientras se borra y el store ya la quitó.
  ExerciseModel? _lastLive;

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
    SessionRoles.instance.isAdmin().then((isAdmin) {
      if (mounted) setState(() => _isAdmin = isAdmin);
    });
  }

  // Contrucción de la descripción
  String _buildSequenceDescription(ExerciseModel ex) {
    return [
      for (var i = 0; i < ex.sequence.length; i++) '${i + 1}. ${describeStep(ex.sequence[i])}',
    ].join('\n');
  }

  void _onBackPressed() => Navigator.pop(context);

  Future<void> _onFavoritePressed(String id, bool current) async {
    if (_actionLoading) return;
    try {
      await ExercisesState.instance.toggleFavorite(id);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar favorito')),
      );
    }
  }

  void _onEditPressed(ExerciseModel ex) {
    if (_actionLoading) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => PingproEditExerciseScreen(exercise: ex)));
  }

  Future<void> _onDeletePressed(ExerciseModel ex) async {
    if (_actionLoading) return;
    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar «${ex.name}»? También se quitará de los entrenamientos que lo usen.',
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Bloquea ⋮ y "Hecho" durante todo el borrado: sin esto se podría abrir
    // otra pantalla o completar el ejercicio justo antes de que este pop lo
    // cierre todo de golpe.
    setState(() => _actionLoading = true);
    try {
      await ExercisesState.instance.delete(ex);
      // En el backend los entrenamientos que lo usaban ya lo han perdido.
      await TrainingsState.instance.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('Ejercicio eliminado')));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _onDonePressed() {
    if (_actionLoading) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ExerciseDone(
            onFinalize: () {
              Navigator.of(context).pop();
              _handleFinalize();
            },
          ),
    );
  }

  Future<void> _handleFinalize() async {
    setState(() => _actionLoading = true);
    final id = widget.exercise.id;

    try {
      await ExercisesState.instance.setCompleted(id, true);
      Navigator.of(context).pop(ExercisesState.instance.getById(id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo marcar como hecho')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos AnimatedBuilder para leer el ejercicio vivo del store
    return AnimatedBuilder(
      animation: ExercisesState.instance,
      builder: (context, _) {
        // Buscar versión "viva" por ID; si el store ya no la tiene (se borró),
        // usar la última viva vista en vez de widget.exercise, que quedó
        // desactualizada si hubo una edición de por medio.
        final live = ExercisesState.instance.getById(widget.exercise.id);
        if (live != null) _lastLive = live;
        final ex = live ?? _lastLive ?? widget.exercise;

        final isFavorite = ex.isFavorite;
        final isCompleted = ex.completedAt != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header con botón de regreso y nombre
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _onBackPressed,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ex.name, style: TextStyles.title)),
                      if (canManage(isOwn: ex.isOwn, isAdmin: _isAdmin))
                        ContentActionsMenu(
                          onEdit: () => _onEditPressed(ex),
                          onDelete: () => _onDeletePressed(ex),
                        ),
                    ],
                  ),
                ),

                // Visualización del widget 3D. La clave es la lista de la
                // secuencia: marcar favorito no la cambia y la animación sigue;
                // editar el ejercicio trae una lista nueva y la animación se
                // rehace con la secuencia nueva.
                Expanded(
                  flex: 2,
                  child: ExerciseAnimationView(key: ObjectKey(ex.sequence), exercise: ex),
                ),

                // Sección inferior con descripción y botones
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Descripción paso a paso
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 200,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Descripción del ejercicio',
                                      style: TextStyles.subTitle,
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ex.description,
                                              style: TextStyles.paragraph,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Pasos:',
                                              style: TextStyles.subTitle,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _buildSequenceDescription(ex),
                                              style: TextStyles.paragraph
                                                  .copyWith(height: 1.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Botones
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón favorito
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.widgetGrayBackground,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed:
                                    () => _onFavoritePressed(ex.id, isFavorite),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Botón "Hecho" (completed sólo aquí)
                            GestureDetector(
                              onTap: _onDonePressed,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isCompleted ? '¡Listo!' : 'Hecho',
                                  style: TextStyles.buttons,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
