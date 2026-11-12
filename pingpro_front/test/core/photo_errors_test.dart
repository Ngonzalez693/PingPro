import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/photo_errors.dart';

void main() {
  test('una foto demasiado grande lo dice', () {
    expect(photoErrorMessage(const PhotoUploadException(413)), 'La foto pesa demasiado. Prueba con otra.');
  });

  test('demasiados cambios seguidos lo dice', () {
    expect(photoErrorMessage(const PhotoUploadException(429)), 'Has cambiado la foto muchas veces. Intenta más tarde.');
  });

  test('sin el almacenamiento de fotos lo dice', () {
    expect(photoErrorMessage(const PhotoUploadException(503)), 'Las fotos de perfil no están disponibles ahora mismo.');
  });

  test('sin conexión usa el mensaje de siempre', () {
    expect(photoErrorMessage(TimeoutException('t')), noConnectionMessage);
    expect(photoErrorMessage(http.ClientException('x')), noConnectionMessage);
    expect(photoErrorMessage(const SocketException('x')), noConnectionMessage);
  });

  test('cualquier otro error da el mensaje general', () {
    expect(photoErrorMessage(const PhotoUploadException(500)), 'No se pudo guardar la foto. Intenta de nuevo.');
    expect(photoErrorMessage(StateError('x')), 'No se pudo guardar la foto. Intenta de nuevo.');
  });

  // Al quitar la foto el mensaje no puede hablar de guardar.
  test('si falla quitar la foto lo dice así', () {
    expect(
      photoErrorMessage(const PhotoUploadException(500), removing: true),
      'No se pudo quitar la foto. Intenta de nuevo.',
    );
    expect(photoErrorMessage(TimeoutException('t'), removing: true), noConnectionMessage);
  });
}
