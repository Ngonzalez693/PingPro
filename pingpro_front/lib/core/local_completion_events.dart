// Eventos de finalización construidos en la app, con la misma forma que los
// que devuelve GET /api/stats/me/events. Los stores los añaden a StatsState
// justo después de un "Hecho" confirmado para que el progreso por sesión se
// actualice sin esperar a la recarga (que luego los sustituye por los del
// servidor). Funciones puras: la fecha llega como parámetro para probarlas.
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/stats_events_model.dart';
import 'package:pingpro_front/models/training_model.dart';

ExerciseCompletionEvent exerciseCompletionEventFor(
  ExerciseModel exercise, {
  required int? session,
  required DateTime at,
}) {
  return ExerciseCompletionEvent(
    exerciseId: exercise.id,
    completedAt: at,
    session: session,
    category: exercise.category,
    hits: _distinctSorted(exercise.sequence.map((step) => step.hit)),
    rotations: _distinctSorted(exercise.sequence.map((step) => step.rotation)),
    deleted: false,
  );
}

TrainingCompletionEvent trainingCompletionEventFor(
  TrainingModel training, {
  required int? session,
  required DateTime at,
}) {
  return TrainingCompletionEvent(
    trainingId: training.id,
    completedAt: at,
    session: session,
    duration: training.duration,
  );
}

// El backend envía los códigos sin repetir y en orden ascendente.
List<int> _distinctSorted(Iterable<int> codes) => codes.toSet().toList()..sort();
