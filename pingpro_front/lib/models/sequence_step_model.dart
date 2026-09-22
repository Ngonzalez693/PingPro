// Un golpe dentro de un ejercicio, codificado con seis enteros.
//
// Espejo en Dart de ISequenceStep del backend. Los números NO son arbitrarios:
// corresponden a los enums de pingpro_back/src/utils/enums.ts
//   hit       HitCode        1 Forehand, 2 Backhand, 4 FH Flick, 7 Servicio…
//   rotation  RotationCode   1 Back spin, 2 Topspin, 5 Drive, 6 Liftado…
//   zone      ZoneCode       1 Corto, 2 Intermedio, 3 Largo, 4 Libre
//   direction DirectionCode  1 Lateral derecho … 7 Lateral izquierdo, 8 Libre
//   side      SideCode       1-2 derecha, 3 medio, 4-5 izquierda
//   ownZone   ZoneCode       profundidad en el propio campo; 4 = sin especificar
//
// Los nombres de cada código y su agrupación están en core/stroke_codes.dart.
import 'package:pingpro_front/core/stroke_codes.dart';

class SequenceStep {
  final int hit;
  final int rotation;
  final int zone;
  final int direction;
  final int side;
  final int ownZone;

  SequenceStep({
    required this.hit,
    required this.rotation,
    required this.zone,
    required this.direction,
    required this.side,
    this.ownZone = ZoneCode.free,
  });

  // Los pasos guardados antes de que existiera ownZone no la traen.
  factory SequenceStep.fromJson(Map<String, dynamic> json) {
    return SequenceStep(
      hit: json['hit'] as int,
      rotation: json['rotation'] as int,
      zone: json['zone'] as int,
      direction: json['direction'] as int,
      side: json['side'] as int,
      ownZone: json['ownZone'] as int? ?? ZoneCode.free,
    );
  }

  Map<String, dynamic> toJson() => {
    'hit': hit,
    'rotation': rotation,
    'zone': zone,
    'direction': direction,
    'side': side,
    'ownZone': ownZone,
  };
}
