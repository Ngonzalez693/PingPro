import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/load_errors.dart';

void main() {
  test('los mensajes son los que ve el usuario', () {
    expect(noConnectionMessage, 'Sin conexión. Revisa tu internet e inténtalo de nuevo.');
    expect(loadFailedMessage, 'No se pudo cargar. Inténtalo de nuevo en un momento.');
  });

  group('loadErrorMessage', () {
    test('sin red al pedir datos (http) es un error de conexión', () {
      expect(loadErrorMessage(http.ClientException('Failed host lookup')), noConnectionMessage);
    });

    test('un socket o TLS que falla es un error de conexión', () {
      expect(loadErrorMessage(const SocketException('Network is unreachable')), noConnectionMessage);
      expect(loadErrorMessage(const HandshakeException('handshake')), noConnectionMessage);
    });

    test('una petición que se pasa de tiempo es un error de conexión', () {
      expect(loadErrorMessage(TimeoutException('lento')), noConnectionMessage);
    });

    // Sin red, lo primero que falla suele ser Firebase renovando el token.
    test('Firebase sin red es un error de conexión', () {
      expect(loadErrorMessage(FirebaseAuthException(code: 'network-request-failed')), noConnectionMessage);
    });

    test('otro error de Firebase no es de conexión', () {
      expect(loadErrorMessage(FirebaseAuthException(code: 'user-token-expired')), loadFailedMessage);
    });

    test('un fallo del servidor da el mensaje genérico, nunca el texto crudo', () {
      expect(loadErrorMessage(Exception('Error al obtener trainings: {"message":"boom"}')), loadFailedMessage);
    });
  });
}
