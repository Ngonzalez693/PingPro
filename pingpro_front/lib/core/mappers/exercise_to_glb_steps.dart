// Traduce un ejercicio a la lista de animaciones 3D que hay que reproducir.
// Es el corazón de la función diferencial de PingPro.
//
// La cadena completa:
//
//   ExerciseModel.sequence            List<SequenceStep> (5 enteros por golpe)
//          ↓  este archivo
//   _hitAnim(step)                    golpe   → nombre de animación
//   _movementBetween(a, b)            traslado entre dos golpes → animación
//          ↓
//   Model3dCatalog.urlByName(nombre)  nombre  → URL del .glb (GET /api/model3d)
//          ↓
//   List<GlbStep>                     lo que consume ExerciseGlbSequenceView
//
// El resultado se intercala así:
//   Posición Inicial → golpe 1 → desplazamiento → golpe 2 → desplazamiento → …
// para que la animación se vea como una secuencia continua y no como golpes
// sueltos. La posición inicial se omite si el ejercicio empieza con un saque,
// porque el saque ya arranca desde su propia postura.
//
// Cuánto dura cada paso ya no se decide aquí: el visor avanza cuando el motor
// avisa de que el clip terminó.
//
// PUNTO FRÁGIL: la unión entre este archivo y la base de datos son cadenas de
// texto. Si el `name` de un documento de 'model3d' no coincide exactamente con
// el literal que se escribe aquí, urlByName devuelve null y ese paso se salta
// en silencio, sin error. Los nombres tienen que mantenerse sincronizados a mano.
import 'dart:math';

import 'package:pingpro_front/core/services/model3d_catalog.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/widgets/exercise_glb_sequence_view.dart';
import 'package:pingpro_front/models/exercise_model.dart';

/// Reduce SideCode (7 valores) a las 4 zonas que distinguen las animaciones.
///
/// Las animaciones no están grabadas por esquina exacta sino por zona, así que
/// varios códigos comparten clip. Esta reducción es lo que evita necesitar una
/// animación por cada combinación posible.
// side: 1-3 derecha, 4-5 pivot, 6-7 izquierda, 8 libre
String _side(int side) {
  if (side == 4 || side == 5) return 'PIVOT';
  if (side == 1 || side == 2 || side == 3) return 'DER';
  if (side == 6 || side == 7) return 'IZQ';
  return 'CENTRO'; // 8 u otros casos
}

/// Golpe → nombre de animación.
///
/// Cascada de reglas sobre (hit, rotation, side). El orden importa: la primera
/// que coincide gana, y las más específicas (pivot) van después de las
/// generales solo porque incluyen la condición de lado.
///
/// Devuelve 'Tpose' como fallback: si una combinación no está contemplada, el
/// muñeco se queda en pose neutra en vez de romper la reproducción. Eso también
/// significa que una combinación sin animación NO se reporta como error — si un
/// ejercicio se ve raro, es el primer sitio donde mirar.
// Golpe → nombre de animación
String? _hitAnim(SequenceStep step) {
  // Saques: hay tres animaciones válidas y se elige una al azar para que
  // repetir el ejercicio no se vea siempre idéntico.
  if (step.hit == 7) {
    final candidates = <String>[
      'Saque Péndulo',
      'Saque Inverso',
      'Saque Backhand',
    ].where((name) => Model3dCatalog.instance.urlByName(name) != null).toList();

    if (candidates.isNotEmpty) {
      candidates.shuffle(Random());
      return candidates.first;
    }
    return 'Saque Péndulo'; // fallback si el catálogo aún no cargó
  }

  // Drive
  if (step.hit == 2 && step.rotation == 5) return 'Backhand drive';

  // Topspin (FH/BH/Pivot)
  if (step.hit == 1 && step.rotation == 2 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Topspin';
  }
  if (step.hit == 2 && step.rotation == 2 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Backhand Topspin';
  }
  if ((step.hit == 1 || step.hit == 2) &&
      step.rotation == 2 &&
      _side(step.side) == 'PIVOT') {
    return 'Pivot Topspin';
  }

  // Loop (FH/BH/Pivot)
  if (step.hit == 1 && step.rotation == 6 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Loop';
  }
  if (step.hit == 2 && step.rotation == 6) return 'Backhand Loop';
  if ((step.hit == 1 || step.hit == 2) &&
      step.rotation == 6 &&
      _side(step.side) == 'PIVOT') {
    return 'LoopPivot';
  }

  // Corte (FH/BH)
  if (step.hit == 1 && step.rotation == 1 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Corte';
  }
  if (step.hit == 2 && step.rotation == 1) {
    return 'Backhand Corte';
    // return 'Backhand Corte Atrás';
  }

  // Flick (FH)
  if (step.hit == 4 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Flick';
  }

  // Ninguno / toques
  if (step.hit == 5 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'NingDer';
  }
  if (step.hit == 5 && _side(step.side) == 'IZQ') return 'NingIzq';

  // Especiales
  if (step.hit == 6) return 'Boomerang';
  // if (...) return 'Hook';
  // if (...) return 'Globo';
  // if (...) return 'Smash';

  // fallback
  return 'Tpose';
}

/// Movimiento entre dos golpes consecutivos.
///
/// Se inserta entre golpe y golpe para que el muñeco se desplace en vez de
/// teletransportarse. Solo depende de la zona de salida y de llegada: cuando
/// coinciden se usa un ajuste corto, y si no, el desplazamiento largo que
/// corresponda.
String? _movementBetween(SequenceStep a, SequenceStep b) {
  final sideA = _side(a.side);
  final sideB = _side(b.side);

  if (sideA == sideB) return 'MovIzqDer'; // ajuste pequeño mismo lado

  // Cambios principales
  if (sideA == 'DER' && sideB == 'IZQ') return 'MovLargoDerIzq';
  if (sideA == 'IZQ' && sideB == 'DER') return 'MovLargoIzqDer';

  // Pivot involucrado
  if (sideA == 'PIVOT' && sideB == 'DER') return 'MovLargoPivotDer';
  if (sideB == 'PIVOT' && sideA == 'DER') return 'MovLargoPivotDer';
  if (sideA == 'PIVOT' && sideB == 'IZQ') return 'MovLargoCruce';
  if (sideB == 'PIVOT' && sideA == 'IZQ') return 'MovLargoCruce';

  // Centro u otros: cruce genérico
  return 'MovLargoCruce';
}

// Construye los GlbStep en orden según la secuencia.
// Inserta intermedios de movimiento cuando haga falta.
// **Sin** wrap-around (no añade transición ni repite la primera).
Future<List<GlbStep>> buildGlbStepsForExercise(ExerciseModel ex) async {
  // El catálogo tiene que estar cargado antes de resolver nombres a URLs.
  // loadIfNeeded es idempotente: solo la primera llamada pega al servidor.
  await Model3dCatalog.instance.loadIfNeeded();

  final out = <GlbStep>[];

  // Posición inicial: solo si primer paso NO es saque
  if (ex.sequence.isNotEmpty && ex.sequence.first.hit != 7) {
    final posIniUrl = Model3dCatalog.instance.urlByName('Posición Inicial');
    if (posIniUrl != null) out.add(GlbStep(url: posIniUrl));
  }

  for (var i = 0; i < ex.sequence.length; i++) {
    final step = ex.sequence[i];

    // 1) Golpe
    final hitName = _hitAnim(step);
    if (hitName != null) {
      final hitUrl = Model3dCatalog.instance.urlByName(hitName);
      if (hitUrl != null) out.add(GlbStep(url: hitUrl));
    }

    // 2) Movimiento hacia el siguiente golpe
    if (i < ex.sequence.length - 1) {
      final next = ex.sequence[i + 1];
      final movName = _movementBetween(step, next);
      if (movName != null) {
        final movUrl = Model3dCatalog.instance.urlByName(movName);
        if (movUrl != null) out.add(GlbStep(url: movUrl));
      }
    }
  }

  // Fallback si no hay nada
  if (out.isEmpty) {
    final tp = Model3dCatalog.instance.urlByName('Tpose');
    if (tp != null) out.add(GlbStep(url: tp));
  }

  return out;
}
