// Qué se le dice al usuario cuando una carga de datos falla. Nunca el texto
// crudo del error: sin red, lo primero que falla suele ser Firebase renovando
// el token, y su mensaje en inglés ("[firebase_auth/network-request-failed]
// …") no le sirve a nadie.
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const noConnectionMessage = 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
const loadFailedMessage = 'No se pudo cargar. Inténtalo de nuevo en un momento.';

/// Si el fallo es de no poder llegar al servidor, no del servidor en sí.
/// http envuelve los SocketException en ClientException; IOException cubre
/// el resto de fallos de red (socket, TLS).
bool _isConnectionError(Object error) =>
    error is IOException ||
    error is http.ClientException ||
    error is TimeoutException ||
    (error is FirebaseAuthException && error.code == 'network-request-failed');

String loadErrorMessage(Object error) =>
    _isConnectionError(error) ? noConnectionMessage : loadFailedMessage;
