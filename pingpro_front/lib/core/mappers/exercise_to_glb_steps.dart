// Traduce un ejercicio a la lista de clips 3D que hay que reproducir.
// Es el corazón de la función diferencial de PingPro.
//
// La secuencia se anima así:
//   Posición Inicial → golpe 1 → desplazamiento → golpe 2 → desplazamiento → …
// La posición inicial se omite si el ejercicio empieza con un saque, porque el
// saque ya arranca desde su propia postura.
//
// Las reglas son de tenis de mesa para un jugador diestro y las definió el
// usuario; están en el spec del 2026-09-21. Los sorteos (saques, salida del
// pivot) hacen que repetir un ejercicio no se vea siempre idéntico.
//
// Todos los clips están en un único .glb; buildGlbStepsForExercise le pone a
// cada uno la URL de ese archivo para que el visor lo reproduzca.
import 'dart:math';

import 'package:pingpro_front/core/animation_clips.dart';
import 'package:pingpro_front/core/services/model3d_catalog.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/widgets/exercise_glb_sequence_view.dart';

const _serveClips = [
  AnimationClip.saquePendulo,
  AnimationClip.saqueInv,
  AnimationClip.saqueReves,
];

const _pivotExitClips = [
  AnimationClip.movLargoPivotDer,
  AnimationClip.movLargoCruce,
];

/// Dónde golpea el jugador a efectos de desplazamiento. El pivot es una
/// posición propia porque se llega a él y se sale de él con clips propios.
/// right, center y left van en el mismo orden que TableSide.
enum _Spot { right, center, left, pivot }

_Spot _spotOf(SequenceStep step) {
  if (isPivot(step)) return _Spot.pivot;
  return _Spot.values[tableSideOf(step.side).index];
}

/// Nombres de los clips que anima [steps], en orden de reproducción.
///
/// [random] solo existe para que los tests fijen los sorteos.
List<String> clipsForSequence(List<SequenceStep> steps, {Random? random}) {
  final rng = random ?? Random();
  final clips = <String>[
    if (steps.isEmpty || steps.first.hit != HitCode.serve) AnimationClip.posInicial,
  ];
  _Spot? previous;
  for (final step in steps) {
    // Es una indicación para el jugador, no un golpe: no se anima.
    if (step.hit == HitCode.untilItFalls) continue;
    // Libre es juego libre: el ejercicio guiado termina aquí.
    if (step.hit == HitCode.free) {
      if (clips.last != AnimationClip.posInicial) clips.add(AnimationClip.posInicial);
      break;
    }
    final spot = _spotOf(step);
    final movement = previous == null ? null : _movementClip(previous, spot, rng);
    if (movement != null) clips.add(movement);
    clips.add(_strokeClip(step, rng));
    previous = spot;
  }
  return clips;
}

String _strokeClip(SequenceStep step, Random random) => switch (step.hit) {
  HitCode.serve => _pickOne(_serveClips, random),
  HitCode.forehand => _forehandClip(step),
  HitCode.backhand => _backhandClip(step.rotation),
  HitCode.forehandOrBackhand => tableSideOf(step.side) == TableSide.left
      ? _backhandClip(step.rotation)
      : _forehandClip(step),
  HitCode.forehandFlick => AnimationClip.flip,
  HitCode.bananaFlick => tableSideOf(step.side) == TableSide.right
      ? AnimationClip.ningDer
      : AnimationClip.ning,
  HitCode.strawberryFlick => AnimationClip.boomerang,
  _ => AnimationClip.posInicial,
};

String _forehandClip(SequenceStep step) {
  final pivot = isPivot(step);
  return switch (step.rotation) {
    RotationCode.backSpin => AnimationClip.corteDer,
    RotationCode.liftado => pivot ? AnimationClip.loopPivot : AnimationClip.loopDerecha,
    _ => pivot ? AnimationClip.topspinPivot : AnimationClip.topspinForehand,
  };
}

String _backhandClip(int rotation) => switch (rotation) {
  RotationCode.backSpin => AnimationClip.corteReves,
  RotationCode.liftado => AnimationClip.inicioReves,
  RotationCode.drive => AnimationClip.reves,
  _ => AnimationClip.topspinBackhand,
};

String? _movementClip(_Spot from, _Spot to, Random random) {
  if (from == to) return null;
  if (to == _Spot.pivot) return AnimationClip.movCortoApivot;
  if (from == _Spot.pivot) {
    // Del pivot a la izquierda el jugador cambia a revés donde está.
    return to == _Spot.left ? null : _pickOne(_pivotExitClips, random);
  }
  // Entre derecha, centro e izquierda: un paso de índice es un
  // desplazamiento corto, dos pasos cruzan la mesa.
  final distance = to.index - from.index;
  if (distance == 1) return AnimationClip.movCortoDerIzq;
  if (distance == -1) return AnimationClip.movCortoIzqDer;
  return distance > 0 ? AnimationClip.movLargoDerIzq : AnimationClip.movLargoIzqDer;
}

String _pickOne(List<String> options, Random random) =>
    options[random.nextInt(options.length)];

/// Pasos listos para el visor. Vacío si models_3d no tiene la fila del
/// archivo de animaciones; la vista enseña entonces su aviso.
Future<List<GlbStep>> buildGlbStepsForExercise(ExerciseModel ex) async {
  final url = await Model3dCatalog.instance.animationsUrl();
  if (url == null) return const [];
  return [
    for (final clip in clipsForSequence(ex.sequence)) GlbStep(url: url, clip: clip),
  ];
}
