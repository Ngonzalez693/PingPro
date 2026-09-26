// Deshacer un "Hecho": borra la última repetición del ejercicio y, si con eso
// algún entrenamiento completado hoy en esa sesión deja de estar completo,
// también su finalización. Así la barra del entrenamiento y Estadísticas no
// se contradicen; volver a hacer el ejercicio lo completa otra vez.
//
// Lo llaman el SnackBar que sale tras "Hecho" y el botón "Deshacer" del
// detalle del ejercicio. Si algo falla, el error sube para enseñarlo.
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/core/session_progress.dart';

Future<void> undoExerciseCompletion(String exerciseId, int session) async {
  await ExercisesState.instance.setCompleted(exerciseId, false);
  // StatsState ya no tiene la repetición deshecha: se ve qué entrenamientos
  // dejan de estar completos sin esperar a la recarga.
  final reopen = trainingsToReopen(
    exerciseId,
    StatsState.instance.events,
    TrainingsState.instance.all,
    session,
  );
  for (final trainingId in reopen) {
    await TrainingsState.instance.setCompleted(trainingId, false);
  }
}
