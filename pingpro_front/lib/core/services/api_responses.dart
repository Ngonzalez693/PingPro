// Lectura de respuestas del backend que comparten varios clientes HTTP.

/// Id del elemento recién creado, a partir de la respuesta de un POST de
/// creación (`/api/exercises/me`, `/api/trainings/me`):
/// `{ "success": true, "data": { "id": "..." } }`.
///
/// Devuelve null si la respuesta no trae un id utilizable. Separada de la
/// petición para poder probarla sin red.
String? parseCreatedId(Object? body) {
  final data = body is Map ? body['data'] : null;
  final id = data is Map ? data['id'] : null;
  return id is String && id.isNotEmpty ? id : null;
}
