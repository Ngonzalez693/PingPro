// Mensajes para cuando no se puede cambiar o quitar la foto de perfil. El
// backend responde con un código por cada caso que el usuario puede entender;
// el resto cae en un mensaje general.
import 'package:pingpro_front/core/load_errors.dart';

class PhotoUploadException implements Exception {
  final int? statusCode;

  const PhotoUploadException(this.statusCode);

  @override
  String toString() => 'PhotoUploadException($statusCode)';
}

const _photoFailedMessage = 'No se pudo guardar la foto. Intenta de nuevo.';

String photoErrorMessage(Object error) {
  if (isConnectionError(error)) return noConnectionMessage;
  if (error is! PhotoUploadException) return _photoFailedMessage;
  return switch (error.statusCode) {
    413 => 'La foto pesa demasiado. Prueba con otra.',
    429 => 'Has cambiado la foto muchas veces. Intenta más tarde.',
    503 => 'Las fotos de perfil no están disponibles ahora mismo.',
    _ => _photoFailedMessage,
  };
}
