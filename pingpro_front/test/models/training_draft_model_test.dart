import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/training_draft_model.dart';

TrainingDraft _draft({
  String name = 'Calentamiento',
  String description = '',
  List<String> exerciseIds = const ['e1', 'e2', 'e1'],
  int minutesPerExercise = 5,
  String? editingId,
}) =>
    TrainingDraft(
      name: name,
      category: 'Grado',
      image: 'assets/images/training_2.jpg',
      description: description,
      exerciseIds: exerciseIds,
      minutesPerExercise: minutesPerExercise,
      editingId: editingId,
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

    test('el destino no viaja en el cuerpo y por defecto es lo propio', () {
      final catalog = TrainingDraft(
        name: 'Base',
        category: 'Grado',
        image: 'assets/images/training_1.jpg',
        exerciseIds: const ['e1'],
        minutesPerExercise: 5,
        scope: ContentScope.catalog,
      );

      expect(catalog.toCreateJson(), isNot(contains('scope')));
      expect(_draft().scope, ContentScope.own);
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

  group('edición', () {
    test('con editingId es una edición; sin él, una creación', () {
      expect(_draft().isEdit, isFalse);
      expect(_draft(editingId: 't1').isEdit, isTrue);
    });

    test('al editar la descripción se manda aunque esté vacía, para poder borrarla', () {
      expect(_draft(editingId: 't1').toCreateJson()['description'], '');
      expect(_draft(editingId: 't1', description: ' Nueva ').toCreateJson()['description'], 'Nueva');
    });
  });
}
