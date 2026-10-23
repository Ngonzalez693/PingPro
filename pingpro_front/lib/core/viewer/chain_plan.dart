// Dónde se coloca cada paso de un ejercicio para que empiece donde terminó el
// anterior, como en un peloteo real, y qué zona del suelo cubre una pasada.
//
// Solo se encadena la posición en el suelo (x, z): la altura y hacia dónde mira
// el jugador salen de cada clip, así sigue mirando hacia donde irá la mesa.
// El primer paso queda donde se grabó, y al repetir el ejercicio se vuelve a
// él: por eso una sola pasada basta para encuadrar la cámara y el jugador no se
// va alejando vuelta tras vuelta.
import 'package:pingpro_front/core/viewer/glb_floor_tracks.dart';

class PlannedStep {
  final String clip;

  /// False si el clip no está en el archivo: el visor se lo salta.
  final bool playable;
  final double offsetX, offsetZ, startX, startZ;

  const PlannedStep({
    required this.clip,
    required this.playable,
    required this.offsetX,
    required this.offsetZ,
    required this.startX,
    required this.startZ,
  });

  Map<String, Object> toJson() => {
        'clip': clip,
        'playable': playable,
        'offsetX': offsetX,
        'offsetZ': offsetZ,
        'startX': startX,
        'startZ': startZ,
      };
}

class FloorBounds {
  final double minX, maxX, minZ, maxZ;

  const FloorBounds({required this.minX, required this.maxX, required this.minZ, required this.maxZ});

  Map<String, Object> toJson() => {'minX': minX, 'maxX': maxX, 'minZ': minZ, 'maxZ': maxZ};
}

class ChainPlan {
  final List<PlannedStep> steps;

  /// Zona del suelo de una pasada completa; null si no hay nada que mostrar.
  final FloorBounds? bounds;

  const ChainPlan({required this.steps, required this.bounds});

  bool get playable => steps.any((s) => s.playable);

  Map<String, Object> toJson() => {
        'steps': [for (final s in steps) s.toJson()],
        if (bounds case final b?) 'bounds': b.toJson(),
      };
}

ChainPlan buildChainPlan(List<String> clips, Map<String, FloorTrack> tracks) {
  final steps = <PlannedStep>[];
  FloorBounds? bounds;
  // Dónde terminó en el suelo el último paso reproducible.
  (double, double)? lastEnd;
  for (final clip in clips) {
    final track = tracks[clip];
    if (track == null) {
      steps.add(PlannedStep(clip: clip, playable: false, offsetX: 0, offsetZ: 0, startX: 0, startZ: 0));
      continue;
    }
    final (offsetX, offsetZ) = switch (lastEnd) {
      null => (0.0, 0.0),
      (final x, final z) => (x - track.startX, z - track.startZ),
    };
    steps.add(PlannedStep(
      clip: clip,
      playable: true,
      offsetX: offsetX,
      offsetZ: offsetZ,
      startX: track.startX,
      startZ: track.startZ,
    ));
    lastEnd = (track.endX + offsetX, track.endZ + offsetZ);
    bounds = _union(bounds, track, offsetX, offsetZ);
  }
  return ChainPlan(steps: steps, bounds: bounds);
}

FloorBounds _union(FloorBounds? b, FloorTrack t, double dx, double dz) {
  final minX = t.minX + dx, maxX = t.maxX + dx, minZ = t.minZ + dz, maxZ = t.maxZ + dz;
  if (b == null) return FloorBounds(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ);
  return FloorBounds(
    minX: minX < b.minX ? minX : b.minX,
    maxX: maxX > b.maxX ? maxX : b.maxX,
    minZ: minZ < b.minZ ? minZ : b.minZ,
    maxZ: maxZ > b.maxZ ? maxZ : b.maxZ,
  );
}
