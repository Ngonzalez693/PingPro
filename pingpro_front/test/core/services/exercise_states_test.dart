import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';

void main() {
  group('parseExerciseStates', () {
    test('lee la respuesta real del backend: {success, data: [...]}', () {
      final states = parseExerciseStates({
        'success': true,
        'data': [
          {
            'exerciseId': 'e1',
            'isFavorite': true,
            'completedAt': '2026-09-10T12:00:00.000Z',
            'updatedAt': '2026-09-11T08:30:00.000Z',
          },
          {'exerciseId': 'e2', 'isFavorite': false, 'completedAt': null},
        ],
      });

      expect(states['e1']?.isFavorite, isTrue);
      expect(states['e1']?.completedAt, DateTime.utc(2026, 9, 10, 12));
      expect(states['e2']?.isFavorite, isFalse);
      expect(states['e2']?.completedAt, isNull);
    });

    test('sin isFavorite cuenta como no favorito', () {
      final states = parseExerciseStates({
        'data': [
          {'exerciseId': 'e1', 'completedAt': '2026-09-10T12:00:00.000Z'},
        ],
      });

      expect(states['e1']?.isFavorite, isFalse);
      expect(states['e1']?.completedAt, isNotNull);
    });

    test('ignora entradas sin exerciseId válido', () {
      final states = parseExerciseStates({
        'data': [
          {'isFavorite': true},
          'no es un objeto',
          {'exerciseId': ''},
        ],
      });

      expect(states, isEmpty);
    });

    test('una fecha en formato Timestamp de Firestore no cuenta como completado', () {
      // Es lo que enviaba el backend antes del arreglo.
      final states = parseExerciseStates({
        'data': [
          {
            'exerciseId': 'e1',
            'completedAt': {'_seconds': 1789148951, '_nanoseconds': 0},
          },
        ],
      });

      expect(states['e1']?.completedAt, isNull);
    });

    test('una respuesta sin lista en data devuelve un índice vacío', () {
      expect(parseExerciseStates(null), isEmpty);
      expect(parseExerciseStates({'success': false}), isEmpty);
      expect(parseExerciseStates([1, 2, 3]), isEmpty);
    });
  });
}
