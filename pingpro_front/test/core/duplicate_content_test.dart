import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/duplicate_content.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/models/training_model.dart';

SequenceStep _step(int hit, {int rotation = 2, int zone = 3, int direction = 1, int side = 1, int ownZone = 4}) =>
    SequenceStep(hit: hit, rotation: rotation, zone: zone, direction: direction, side: side, ownZone: ownZone);

ExerciseModel _exercise(String name, List<SequenceStep> sequence, {String? ownerId}) => ExerciseModel(
  id: name,
  ownerId: ownerId,
  name: name,
  category: 'Técnico',
  image: '',
  description: '',
  sequence: sequence,
);

TrainingModel _training(String name, List<String> exerciseIds, {String? ownerId}) => TrainingModel(
  id: name,
  ownerId: ownerId,
  name: name,
  category: 'Grado',
  image: '',
  description: '',
  exerciseIds: exerciseIds,
  duration: 30,
);

void main() {
  group('findSameExercise', () {
    test('encuentra uno con los mismos golpes aunque tenga otro nombre', () {
      final existing = _exercise('Topspin cruzado', [_step(1), _step(2)]);

      expect(findSameExercise([_step(1), _step(2)], [existing]), existing);
    });

    test('no hay coincidencia si un golpe difiere en un solo campo', () {
      final existing = _exercise('Topspin cruzado', [_step(1), _step(2)]);

      expect(findSameExercise([_step(1), _step(2, ownZone: 3)], [existing]), isNull);
    });

    test('los mismos golpes en otro orden no son el mismo ejercicio', () {
      final existing = _exercise('Topspin cruzado', [_step(1), _step(2)]);

      expect(findSameExercise([_step(2), _step(1)], [existing]), isNull);
    });

    test('una secuencia más larga no es el mismo ejercicio', () {
      final existing = _exercise('Topspin cruzado', [_step(1), _step(2)]);

      expect(findSameExercise([_step(1), _step(2), _step(1)], [existing]), isNull);
    });

    test('si hay varios, prefiere el propio al del catálogo', () {
      final catalog = _exercise('Catálogo', [_step(1)]);
      final own = _exercise('Mío', [_step(1)], ownerId: 'u1');

      expect(findSameExercise([_step(1)], [catalog, own]), own);
    });
  });

  group('findSameTraining', () {
    test('encuentra uno con los mismos ejercicios en el mismo orden', () {
      final existing = _training('Calentamiento', ['e1', 'e2']);

      expect(findSameTraining(['e1', 'e2'], [existing]), existing);
    });

    test('los mismos ejercicios en otro orden no son el mismo entrenamiento', () {
      final existing = _training('Calentamiento', ['e1', 'e2']);

      expect(findSameTraining(['e2', 'e1'], [existing]), isNull);
    });

    test('un ejercicio repetido cuenta cada vez que aparece', () {
      final existing = _training('Calentamiento', ['e1', 'e2']);

      expect(findSameTraining(['e1', 'e1', 'e2'], [existing]), isNull);
    });

    test('si hay varios, prefiere el propio al del catálogo', () {
      final catalog = _training('Catálogo', ['e1']);
      final own = _training('Mío', ['e1'], ownerId: 'u1');

      expect(findSameTraining(['e1'], [catalog, own]), own);
    });
  });

  group('mensajes', () {
    test('un ejercicio propio se nombra como tuyo', () {
      final own = _exercise('Mi topspin', [_step(1)], ownerId: 'u1');

      expect(sameExerciseMessage(own), 'Ya tienes un ejercicio igual: «Mi topspin». ¿Crearlo de todos modos?');
    });

    test('un entrenamiento del catálogo se nombra como del catálogo', () {
      final catalog = _training('Calentamiento', ['e1']);

      expect(
        sameTrainingMessage(catalog),
        'Ya existe un entrenamiento igual en el catálogo: «Calentamiento». ¿Crearlo de todos modos?',
      );
    });
  });
}
