// Si lo que se va a crear ya existe, entre lo propio y el catálogo que tienen
// los stores. Cuenta el contenido, no el nombre: un ejercicio es su secuencia
// de golpes y un entrenamiento su lista ordenada de ejercicios.
//
// Solo sirve para avisar antes de crear: el usuario puede crearlo igual (p. ej.
// para tener su propia copia de uno del catálogo y editarla).
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/models/training_model.dart';

/// Un ejercicio con los mismos golpes en el mismo orden, o null. Si hay
/// varios, uno propio: avisar de que ya lo tienes es más útil que del catálogo.
ExerciseModel? findSameExercise(List<SequenceStep> sequence, Iterable<ExerciseModel> exercises) =>
    _preferOwn(exercises.where((e) => _sameSequence(e.sequence, sequence)), (e) => e.isOwn);

/// Un entrenamiento con los mismos ejercicios en el mismo orden, o null; como
/// en findSameExercise, si hay varios, uno propio.
TrainingModel? findSameTraining(List<String> exerciseIds, Iterable<TrainingModel> trainings) =>
    _preferOwn(trainings.where((t) => _sameIds(t.exerciseIds, exerciseIds)), (t) => t.isOwn);

String sameExerciseMessage(ExerciseModel match) => _message('ejercicio', match.name, match.isOwn);

String sameTrainingMessage(TrainingModel match) => _message('entrenamiento', match.name, match.isOwn);

String _message(String kind, String name, bool isOwn) => isOwn
    ? 'Ya tienes un $kind igual: «$name». ¿Crearlo de todos modos?'
    : 'Ya existe un $kind igual en el catálogo: «$name». ¿Crearlo de todos modos?';

T? _preferOwn<T>(Iterable<T> matches, bool Function(T) isOwn) =>
    [...matches.where(isOwn), ...matches].firstOrNull;

bool _sameIds(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameSequence(List<SequenceStep> a, List<SequenceStep> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_sameStep(a[i], b[i])) return false;
  }
  return true;
}

bool _sameStep(SequenceStep a, SequenceStep b) =>
    a.hit == b.hit &&
    a.rotation == b.rotation &&
    a.zone == b.zone &&
    a.direction == b.direction &&
    a.side == b.side &&
    a.ownZone == b.ownZone;
