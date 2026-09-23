import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/api_paths.dart';
import 'package:pingpro_front/models/content_scope.dart';

void main() {
  group('createPathFor', () {
    test('lo propio va a /me, que acepta cualquier sesión', () {
      expect(createPathFor('exercises', ContentScope.own), '/api/exercises/me');
      expect(createPathFor('trainings', ContentScope.own), '/api/trainings/me');
    });

    test('el catálogo va a la raíz, reservada a los admins', () {
      expect(createPathFor('exercises', ContentScope.catalog), '/api/exercises');
      expect(createPathFor('trainings', ContentScope.catalog), '/api/trainings');
    });
  });

  group('itemPathFor', () {
    test('lo propio va a /me/:id, que solo deja tocar lo del usuario', () {
      expect(itemPathFor('exercises', 'e1', own: true), '/api/exercises/me/e1');
      expect(itemPathFor('trainings', 't1', own: true), '/api/trainings/me/t1');
    });

    test('el catálogo va a /:id, reservada a los admins', () {
      expect(itemPathFor('exercises', 'e1', own: false), '/api/exercises/e1');
      expect(itemPathFor('trainings', 't1', own: false), '/api/trainings/t1');
    });
  });
}
