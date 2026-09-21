import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/training_draft_model.dart';

TrainingDraft _draft({
  String name = 'Calentamiento',
  String description = '',
  List<String> exerciseIds = const ['e1', 'e2', 'e1'],
  int minutesPerExercise = 5,
}) =>
    TrainingDraft(
      name: name,
      category: 'Grado',
      image: 'assets/images/training_2.jpg',
      description: description,
      exerciseIds: exerciseIds,
      minutesPerExercise: minutesPerExercise,
    );

void main() {
  group('totalMinutes', () {
    test('es el tiempo por ejercicio por la cantidad de ejercicios', () {
      expect(_draft(minutesPerExercise: 5).totalMinutes, 15); // 3 ejercicios
    });

    test('un ejercicio repetido cuenta cada vez que aparece', () {
      expect(_draft(exerciseIds: ['e1', 'e1', 'e1', 'e1'], minutesPerExercise: 2).totalMinutes, 8);
    });

    test('sin ejercicios es cero', () {
      expect(_draft(exerciseIds: []).totalMinutes, 0);
    });
  });

  group('toCreateJson', () {
    test('lleva solo los campos que acepta el backend', () {
      expect(
        _draft(description: 'Para empezar').toCreateJson().keys,
        unorderedEquals(['name', 'category', 'image', 'description', 'exerciseIds', 'duration']),
      );
    });

    test('manda la duración total, no la de cada ejercicio', () {
      expect(_draft(minutesPerExercise: 4).toCreateJson()['duration'], 12);
    });

    test('conserva el orden y los repetidos de los ejercicios', () {
      expect(_draft().toCreateJson()['exerciseIds'], ['e1', 'e2', 'e1']);
    });

    test('sin descripción, el campo no se manda', () {
      expect(_draft().toCreateJson(), isNot(contains('description')));
      expect(_draft(description: '  ').toCreateJson(), isNot(contains('description')));
    });

    test('recorta los espacios del nombre', () {
      expect(_draft(name: '  Rutina  ').toCreateJson()['name'], 'Rutina');
    });
  });
}
