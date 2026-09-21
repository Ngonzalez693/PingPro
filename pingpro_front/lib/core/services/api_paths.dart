// Rutas de la API que dependen de a dónde va lo que se crea.
import 'package:pingpro_front/models/content_scope.dart';

/// Ruta del POST de creación de `collection` ('exercises', 'trainings').
///
/// El catálogo va a la raíz, que el backend reserva a los admins; lo propio va
/// a /me, que acepta cualquier sesión. Equivocarse aquí escribiría en el sitio
/// equivocado, por eso está aislada y probada.
String createPathFor(String collection, ContentScope scope) {
  switch (scope) {
    case ContentScope.catalog:
      return '/api/$collection';
    case ContentScope.own:
      return '/api/$collection/me';
  }
}
