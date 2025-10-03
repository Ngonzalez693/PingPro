import 'dart:math';

import 'package:pingpro_front/core/services/model3d_catalog.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/widgets/exercise_glb_sequence_view.dart';
import 'package:pingpro_front/models/exercise_model.dart';

/// Duraciones por animación
const Map<String, Duration> _durByName = {
  // GOLPES
  'Saque Péndulo': Duration(seconds: 5),
  'Saque Inverso': Duration(seconds: 5),
  'Saque Backhand': Duration(seconds: 4),
  'Backhand drive': Duration(seconds: 4),
  'Forehand Topspin': Duration(seconds: 3),
  'Backhand Topspin': Duration(seconds: 4),
  'Pivot Topspin': Duration(seconds: 4),
  'Forehand Loop': Duration(seconds: 5),
  'Backhand Loop': Duration(seconds: 4),
  'LoopPivot': Duration(seconds: 4),
  'Forehand Corte': Duration(seconds: 4),
  'Backhand Corte': Duration(seconds: 3),
  'Backhand Corte Atrás': Duration(seconds: 4),
  'Forehand Flick': Duration(seconds: 4),
  'NingDer': Duration(seconds: 5),
  'NingIzq': Duration(seconds: 4),
  'Boomerang': Duration(seconds: 4),
  'Hook': Duration(seconds: 4),
  'Globo': Duration(seconds: 5),
  // MOVIMIENTOS
  'MovCortoDerIzq': Duration(seconds: 3),
  'MovCortoIzqDer': Duration(seconds: 3),
  'MovCortoAPivot': Duration(seconds: 3),
  'MovLargoDerIzq': Duration(seconds: 3),
  'MovLargoIzqDer': Duration(seconds: 3),
  'MovLargoPivotDer': Duration(seconds: 3),
  'MovLargoCruce': Duration(seconds: 4),
  'MovIzqDer': Duration(seconds: 4),
  'Posición Inicial': Duration(seconds: 4),
  'Tpose': Duration(seconds: 1),
};

// side: 1-3 derecha, 4-5 pivot, 6-7 izquierda, 8 libre
String _side(int side) {
  if (side == 4 || side == 5) return 'PIVOT';
  if (side == 1 || side == 2 || side == 3) return 'DER';
  if (side == 6 || side == 7) return 'IZQ';
  return 'CENTRO'; // 8 u otros casos
}

// Golpe → nombre de animación
String? _hitAnim(SequenceStep step) {
  // Saques
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

/// Movimiento entre dos golpes consecutivos
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
  await Model3dCatalog.instance.loadIfNeeded();

  final out = <GlbStep>[];

  // Posición inicial: solo si primer paso NO es saque
  if (ex.sequence.isNotEmpty && ex.sequence.first.hit != 7) {
    final posIniUrl = Model3dCatalog.instance.urlByName('Posición Inicial');
    if (posIniUrl != null) {
      out.add(GlbStep(
        url: posIniUrl,
        duration: _durByName['Posición Inicial']!,
      ));
    }
  }

  for (var i = 0; i < ex.sequence.length; i++) {
    final step = ex.sequence[i];

    // 1) Golpe
    final hitName = _hitAnim(step);
    if (hitName != null) {
      final hitUrl = Model3dCatalog.instance.urlByName(hitName);
      if (hitUrl != null) {
        final dur = _durByName[hitName] ?? const Duration(seconds: 3);
        out.add(GlbStep(url: hitUrl, duration: dur));
      }
    }

    // 2) Movimiento hacia el siguiente golpe
    if (i < ex.sequence.length - 1) {
      final next = ex.sequence[i + 1];
      final movName = _movementBetween(step, next);
      if (movName != null) {
        final movUrl = Model3dCatalog.instance.urlByName(movName);
        if (movUrl != null) {
          final dur = _durByName[movName] ?? const Duration(seconds: 2);
          out.add(GlbStep(url: movUrl, duration: dur));
        }
      }
    }
  }

  // Fallback si no hay nada
  if (out.isEmpty) {
    final tp = Model3dCatalog.instance.urlByName('Tpose');
    if (tp != null) {
      out.add(GlbStep(url: tp, duration: _durByName['Tpose']!));
    }
  }

  return out;
}
