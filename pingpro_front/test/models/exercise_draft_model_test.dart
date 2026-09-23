import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/exercise_draft_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

final _step = SequenceStep(hit: 1, rotation: 2, zone: 3, direction: 6, side: 1);

ExerciseDraft _draft({String name = 'Topspin cruzado', String description = ''}) => ExerciseDraft(
      name: name,
      category: 'Técnico',
      image: 'assets/images/exercise_2.jpg',
      description: description,
      sequence: [_step],
    );

void main() {
  group('toCreateJson', () {
    test('lleva solo los campos que acepta el backend', () {
      // El esquema Joi rechaza campos desconocidos: id, isFavorite, completedAt
      // u ownerId harían fallar la creación con un 400.
      expect(
        _draft(description: 'Cruzado desde el revés').toCreateJson().keys,
        unorderedEquals(['name', 'category', 'image', 'description', 'sequence']),
      );
    });

    test('el destino no viaja en el cuerpo: decide la ruta, no un campo', () {
      final draft = ExerciseDraft(
        name: 'Saque',
        category: 'Técnico',
        image: 'assets/images/exercise_1.jpg',
        sequence: [_step],
        scope: ContentScope.catalog,
      );

      expect(draft.toCreateJson(), isNot(contains('scope')));
    });

    test('sin decir nada, el destino es lo propio del usuario', () {
      expect(_draft().scope, ContentScope.own);
    });

    test('sin descripción, el campo no se manda', () {
      expect(_draft().toCreateJson(), isNot(contains('description')));
      expect(_draft(description: '   ').toCreateJson(), isNot(contains('description')));
    });

    test('al editar con descripción vacía, sí se manda para poder borrarla', () {
      final editing = ExerciseDraft(
        name: 'Topspin cruzado',
        category: 'Técnico',
        image: 'assets/images/exercise_2.jpg',
        sequence: [_step],
        editingId: 'e1',
      );

      expect(editing.toCreateJson()['description'], '');
    });

    test('recorta los espacios del nombre y la descripción', () {
      final json = _draft(name: '  Saque corto  ', description: ' Al medio ').toCreateJson();

      expect(json['name'], 'Saque corto');
      expect(json['description'], 'Al medio');
    });

    test('la secuencia va con los cinco códigos de cada golpe', () {
      expect(_draft().toCreateJson()['sequence'], [
        {'hit': 1, 'rotation': 2, 'zone': 3, 'direction': 6, 'side': 1, 'ownZone': 4},
      ]);
    });
  });

  group('toPreviewModel', () {
    test('conserva lo que necesita la vista previa y no tiene id todavía', () {
      final model = _draft(description: 'Nota').toPreviewModel();

      expect(model.id, isEmpty);
      expect(model.name, 'Topspin cruzado');
      expect(model.image, 'assets/images/exercise_2.jpg');
      expect(model.sequence, [_step]);
      expect(model.isFavorite, isFalse);
      expect(model.completedAt, isNull);
    });
  });

  test('un borrador con editingId es una edición; sin él, una creación', () {
    final creating = ExerciseDraft(name: 'a', category: 'Técnico', image: 'i', sequence: [_step]);
    final editing = ExerciseDraft(name: 'a', category: 'Técnico', image: 'i', sequence: [_step], editingId: 'e1');

    expect(creating.isEdit, isFalse);
    expect(editing.isEdit, isTrue);
  });
}
