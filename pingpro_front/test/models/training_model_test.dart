import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/training_model.dart';

Map<String, dynamic> _json({String? ownerId}) => {
      'id': 't1',
      if (ownerId != null) 'ownerId': ownerId,
      'name': 'Calentamiento',
      'category': 'Grado',
      'image': 'assets/images/training_1.jpg',
      'exerciseIds': ['e1', 'e2'],
      'duration': 10,
    };

void main() {
  test('con ownerId es un entrenamiento propio', () {
    final training = TrainingModel.fromJson(_json(ownerId: 'u1'));

    expect(training.ownerId, 'u1');
    expect(training.isOwn, isTrue);
  });

  test('sin ownerId es del catálogo', () {
    expect(TrainingModel.fromJson(_json()).isOwn, isFalse);
  });
}
