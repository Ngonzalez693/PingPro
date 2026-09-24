import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

void main() {
  group('parseStatsEvents', () {
    test('lee la respuesta real del backend', () {
      final events = parseStatsEvents({
        'success': true,
        'data': {
          'exerciseCompletions': [
            {
              'exerciseId': 'e1',
              'completedAt': '2026-09-10T12:00:00.000Z',
              'session': 2,
              'category': 'Técnico',
              'hits': [1, 4],
              'rotations': [2],
              'deleted': false,
            },
          ],
          'trainingCompletions': [
            {'trainingId': 't1', 'completedAt': '2026-09-11T08:00:00.000Z', 'session': null, 'duration': 45},
          ],
          'created': [
            {'kind': 'training', 'id': 't9', 'createdAt': '2026-09-01T10:00:00.000Z'},
          ],
        },
      });

      final exercise = events.exerciseCompletions.single;
      expect(exercise.exerciseId, 'e1');
      expect(exercise.completedAt.isAtSameMomentAs(DateTime.utc(2026, 9, 10, 12)), isTrue);
      expect(exercise.session, 2);
      expect(exercise.category, 'Técnico');
      expect(exercise.hits, [1, 4]);
      expect(exercise.rotations, [2]);
      expect(exercise.deleted, isFalse);

      final training = events.trainingCompletions.single;
      expect(training.trainingId, 't1');
      expect(training.session, isNull);
      expect(training.duration, 45);

      final created = events.created.single;
      expect(created.kind, CreatedKind.training);
      expect(created.id, 't9');
    });

    test('pasa las fechas a hora local para agrupar por día del teléfono', () {
      final events = parseStatsEvents({
        'data': {
          'exerciseCompletions': [
            {'exerciseId': 'e1', 'completedAt': '2026-09-10T12:00:00.000Z', 'category': 'Técnico'},
          ],
        },
      });

      expect(events.exerciseCompletions.single.completedAt.isUtc, isFalse);
    });

    test('las listas que faltan quedan vacías y los campos opcionales toman su valor por defecto', () {
      final events = parseStatsEvents({
        'data': {
          'exerciseCompletions': [
            {'exerciseId': 'e1', 'completedAt': '2026-09-10T12:00:00.000Z', 'category': 'Footwork'},
          ],
        },
      });

      final exercise = events.exerciseCompletions.single;
      expect(exercise.session, isNull);
      expect(exercise.hits, isEmpty);
      expect(exercise.rotations, isEmpty);
      expect(exercise.deleted, isFalse);
      expect(events.trainingCompletions, isEmpty);
      expect(events.created, isEmpty);
    });

    test('descarta entradas sin id, sin fecha válida o de un tipo desconocido', () {
      final events = parseStatsEvents({
        'data': {
          'exerciseCompletions': [
            {'completedAt': '2026-09-10T12:00:00.000Z', 'category': 'Técnico'},
            {'exerciseId': 'e1', 'completedAt': 'ayer', 'category': 'Técnico'},
            {'exerciseId': 'e2', 'completedAt': '2026-09-10T12:00:00.000Z'},
            'no es un objeto',
          ],
          'trainingCompletions': [
            {'trainingId': '', 'completedAt': '2026-09-11T08:00:00.000Z'},
          ],
          'created': [
            {'kind': 'model3d', 'id': 'x', 'createdAt': '2026-09-01T10:00:00.000Z'},
          ],
        },
      });

      expect(events.exerciseCompletions, isEmpty);
      expect(events.trainingCompletions, isEmpty);
      expect(events.created, isEmpty);
    });

    test('una sesión fuera de 1..3 se trata como sin sesión', () {
      final events = parseStatsEvents({
        'data': {
          'trainingCompletions': [
            {'trainingId': 't1', 'completedAt': '2026-09-11T08:00:00.000Z', 'session': 4},
          ],
        },
      });

      expect(events.trainingCompletions.single.session, isNull);
    });

    test('sin data lanza FormatException', () {
      expect(() => parseStatsEvents({'success': false}), throwsFormatException);
      expect(() => parseStatsEvents('texto'), throwsFormatException);
    });
  });
}
