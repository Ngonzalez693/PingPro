import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/exercise_model.dart';

Map<String, dynamic> _json({String? ownerId}) => {
      'id': 'e1',
      if (ownerId != null) 'ownerId': ownerId,
      'name': 'Topspin cruzado',
      'category': 'Técnico',
      'image': 'assets/images/exercise_1.jpg',
      'sequence': [],
    };

void main() {
  group('ownerId', () {
    test('un ejercicio privado trae su dueño y es del usuario', () {
      final exercise = ExerciseModel.fromJson(_json(ownerId: 'u1'));

      expect(exercise.ownerId, 'u1');
      expect(exercise.isOwn, isTrue);
    });

    test('uno del catálogo llega sin ownerId y no es del usuario', () {
      // El backend omite el campo en el catálogo, no lo manda a null.
      final exercise = ExerciseModel.fromJson(_json());

      expect(exercise.ownerId, isNull);
      expect(exercise.isOwn, isFalse);
    });
  });
}
