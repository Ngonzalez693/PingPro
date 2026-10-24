// Mensajes entre la app y la página del visor 3D (assets/viewer/viewer.js).
//
// Página → app: JSON por el canal 'PingPro' (listo, paso en curso, error).
// App → página: llamadas a funciones globales de la página. Los valores van
// con jsonEncode, que produce literales JavaScript válidos y escapados.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pingpro_front/core/viewer/chain_plan.dart';

const viewerChannel = 'PingPro';

sealed class ViewerEvent {
  const ViewerEvent();
}

/// La página cargó three.js y el archivo de animaciones: ya acepta el plan.
class ViewerReady extends ViewerEvent {
  const ViewerReady();
}

class ViewerPlaying extends ViewerEvent {
  final int index;

  const ViewerPlaying(this.index);
}

class ViewerError extends ViewerEvent {
  final String message;

  const ViewerError(this.message);
}

/// null para lo que no se entiende: un mensaje raro no debe tumbar el visor.
ViewerEvent? parseViewerEvent(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    debugPrint('Visor 3D: mensaje ilegible: $e');
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  return switch (decoded) {
    {'type': 'ready'} => const ViewerReady(),
    {'type': 'playing', 'index': final int index} => ViewerPlaying(index),
    {'type': 'error', 'message': final String message} => ViewerError(message),
    _ => null,
  };
}

String loadCommand(ChainPlan plan) => 'ppLoad(${jsonEncode(plan.toJson())})';

const pauseCommand = 'ppPause()';
const resumeCommand = 'ppResume()';

/// [backwards] decide hacia dónde se buscan los pasos que se pueden
/// reproducir si [index] no lo es (con ◀, hacia atrás).
String goToCommand(int index, {bool backwards = false}) => 'ppGoTo($index, ${backwards ? -1 : 1})';
