import 'dart:math';

import 'package:pingpro_front/core/services/model3d_catalog.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/widgets/exercise_glb_sequence_view.dart';
import 'package:pingpro_front/models/exercise_model.dart';

/// Duraciones por animación
const Map<String, Duration> _durByName = {
  // GOLPES
  'Saque Péndulo': Duration(seconds: 3),
  'Saque Inverso': Duration(seconds: 3),
  'Saque Backhand': Duration(seconds: 3),
  'Backhand drive': Duration(seconds: 3),
  'Forehand Topspin': Duration(seconds: 3),
  'Backhand Topspin': Duration(seconds: 3),
  'Pivot Topspin': Duration(seconds: 3),
  'Forehand Loop': Duration(seconds: 3),
  'Backhand Loop': Duration(seconds: 3),
  'LoopPivot': Duration(seconds: 3),
  'Forehand Corte': Duration(seconds: 3),
  'Backhand Corte': Duration(seconds: 3),
  'Backhand Corte Atrás': Duration(seconds: 3),
  'Forehand Flick': Duration(seconds: 3),
  'NingDer': Duration(seconds: 3),
  'NingIzq': Duration(seconds: 3),
  'Boomerang': Duration(seconds: 3),
  'Hook': Duration(seconds: 3),
  'Globo': Duration(seconds: 3),
  // MOVIMIENTOS
  'MovCortoDerIzq': Duration(seconds: 2),
  'MovCortoIzqDer': Duration(seconds: 2),
  'MovCortoAPivot': Duration(seconds: 2),
  'MovLargoDerIzq': Duration(seconds: 3),
  'MovLargoIzqDer': Duration(seconds: 3),
  'MovLargoPivotDer': Duration(seconds: 3),
  'MovLargoCruce': Duration(seconds: 3),
  'MovIzqDer': Duration(seconds: 2),
  'Posición Inicial': Duration(seconds: 1),
  'Tpose': Duration(seconds: 1),
};

// side: 1-3 derecha, 4-5 pivot, 6-7 izquierda, 8 libre
String _side(int side) {
  if (side == 4 || side == 5) return 'PIVOT';
  if (side == 1 || side == 2 || side == 3) return 'DER';
  if (side == 6 || side == 7) return 'IZQ';
  // 8=Libre u otros casos:
  return 'CENTRO';
}

// Golpe
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
  if (step.hit == 2 && step.rotation == 5) {
    return 'Backhand drive';
  }

  // Topspin (FH/BH/Pivot)
  if (step.hit == 1 && step.rotation == 2 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Topspin';
  }
  if (step.hit == 2 && step.rotation == 2 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Backhand Topspin';
  }
  if ((step.hit == 1 || step.hit == 2) && step.rotation == 2 && _side(step.side) == 'PIVOT') {
    return 'Pivot Topspin';
  }

  // Loop (FH/BH/Pivot)
  if (step.hit == 1 && step.rotation == 6 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Loop';
  }
  if (step.hit == 2 && step.rotation == 6) {
    return 'Backhand Loop';
  }
  if ((step.hit == 1 || step.hit == 2) && step.rotation == 6 && _side(step.side) == 'PIVOT') {
    return 'LoopPivot';
  }

  // Corte (FH/BH)
  if (step.hit == 1 && step.rotation == 1 && (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Corte';
  }
  if (step.hit == 2 && step.rotation == 1) {
    return 'Backhand Corte';
    // return 'Backhand Corte Atrás';
  }

  // Flick (FH)
  if (step.hit == 4 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'Forehand Flick';
  }

  // Ninguno / toques
  if (step.hit == 5 &&
      (_side(step.side) == 'DER' || _side(step.side) == 'CENTRO')) {
    return 'NingDer';
  }
  if (step.hit == 5 && _side(step.side) == 'IZQ') {
    return 'NingIzq';
  }

  // Especiales
  if (step.hit == 6) {
    return 'Boomerang';
  }
  // if (X) return 'Hook';
  // if (Y) return 'Globo';
  // if (Z) return 'Smash';

  // fallback
  return 'Tpose';
}

/// Movimiento entre dos golpes consecutivos
String? _movementBetween(SequenceStep a, SequenceStep b) {
  final sideA = _side(a.side);
  final sideB = _side(b.side);

  // Si no hay cambio significativo de posición, no metemos movimiento
  if (sideA == sideB) {
    // mismo lado → pequeño ajuste
    return 'MovIzqDer';
  }

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

// Construye los GlbStep en orden según la secuencia del ejercicio.
// Inserta intermedios de movimiento cuando haga falta.
Future<List<GlbStep>> buildGlbStepsForExercise(ExerciseModel ex) async {
  await Model3dCatalog.instance.loadIfNeeded();

  final out = <GlbStep>[];

  // Posición inicial: solo si primer paso NO es saque
  if (ex.sequence.isNotEmpty && ex.sequence.first.hit != 7) {
    final posIniUrl = Model3dCatalog.instance.urlByName('Posición Inicial');
    if (posIniUrl != null) {
      out.add(GlbStep(url: posIniUrl, duration: _durByName['Posición Inicial']!));
    }
  }

  for (var i = 0; i < ex.sequence.length; i++) {
    final step = ex.sequence[i];

    // 1) Animación de golpe
    final hitName = _hitAnim(step);
    if (hitName != null) {
      final hitUrl = Model3dCatalog.instance.urlByName(hitName);
      if (hitUrl != null) {
        final dur = _durByName[hitName] ?? const Duration(seconds: 3);
        out.add(GlbStep(url: hitUrl, duration: dur));
      }
    }

    // 2) Movimiento hacia el siguiente golpe (si existe)
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

  // Si por alguna razón no resolvimos nada, devolver Tpose
  if (out.isEmpty) {
    final tp = Model3dCatalog.instance.urlByName('Tpose');
    if (tp != null) {
      out.add(GlbStep(url: tp, duration: _durByName['Tpose']!));
    }
  }

  return out;
}
