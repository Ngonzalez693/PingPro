import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/local_completion_events.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/models/training_model.dart';

SequenceStep _step(int hit, int rotation) =>
    SequenceStep(hit: hit, rotation: rotation, zone: 1, direction: 1, side: 1);

ExerciseModel _exercise(List<SequenceStep> sequence) => ExerciseModel(
  id: 'ex1',
  name: 'Ejercicio',
  category: 'Ataque',
  image: 'img.png',
  description: '',
  sequence: sequence,
);

void main() {
  final at = DateTime(2026, 9, 24, 18, 30);

  test('el evento de ejercicio lleva los códigos distintos y ordenados', () {
    final exercise = _exercise([_step(7, 5), _step(1, 2), _step(7, 2), _step(2, 1)]);

    final event = exerciseCompletionEventFor(exercise, session: 2, at: at);

    expect(event.hits, [1, 2, 7]);
    expect(event.rotations, [1, 2, 5]);
  });

  test('el evento de ejercicio copia id, categoría, sesión y fecha, y no está borrado', () {
    final event = exerciseCompletionEventFor(_exercise([_step(1, 1)]), session: 3, at: at);

    expect(event.exerciseId, 'ex1');
    expect(event.category, 'Ataque');
    expect(event.session, 3);
    expect(event.completedAt, at);
    expect(event.deleted, isFalse);
  });

  test('sin secuencia el evento de ejercicio no lleva códigos', () {
    final event = exerciseCompletionEventFor(_exercise([]), session: null, at: at);

    expect(event.hits, isEmpty);
    expect(event.rotations, isEmpty);
    expect(event.session, isNull);
  });

  test('el evento de entrenamiento copia id, duración, sesión y fecha', () {
    final training = TrainingModel(
      id: 'tr1',
      name: 'Entrenamiento',
      category: '',
      image: 'img.png',
      description: '',
      exerciseIds: const ['ex1'],
      duration: 45,
    );

    final event = trainingCompletionEventFor(training, session: 1, at: at);

    expect(event.trainingId, 'tr1');
    expect(event.duration, 45);
    expect(event.session, 1);
    expect(event.completedAt, at);
  });
}
