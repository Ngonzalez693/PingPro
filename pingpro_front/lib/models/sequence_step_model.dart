/// Un golpe dentro de un ejercicio, codificado con cinco enteros.
///
/// Espejo en Dart de ISequenceStep del backend. Los números NO son arbitrarios:
/// corresponden a los enums de pingpro_back/src/utils/enums.ts
///   hit       HitCode        1 Forehand, 2 Backhand, 4 FH Flick, 7 Servicio…
///   rotation  RotationCode   1 Back spin, 2 Topspin, 5 Drive, 6 Liftado…
///   zone      ZoneCode       1 Corto, 2 Intermedio, 3 Largo, 4 Libre
///   direction DirectionCode  1 Lateral derecho … 7 Lateral izquierdo, 8 Libre
///   side      SideCode       1-3 derecha, 4-5 pivot, 6-7 izquierda
///
/// DEUDA TÉCNICA: aquí son `int` pelados y la tabla de significados está
/// duplicada a mano en pingpro_exercise_detail_screen.dart y en
/// core/mappers/exercise_to_glb_steps.dart. Si el backend cambia un código, hay
/// tres sitios que actualizar. Convendría un enum compartido en core/.
class SequenceStep {
  final int hit;
  final int rotation;
  final int zone;
  final int direction;
  final int side;

  SequenceStep({
    required this.hit,
    required this.rotation,
    required this.zone,
    required this.direction,
    required this.side,
  });

  factory SequenceStep.fromJson(Map<String, dynamic> json) {
    return SequenceStep(
      hit: json['hit'] as int,
      rotation: json['rotation'] as int,
      zone: json['zone'] as int,
      direction: json['direction'] as int,
      side: json['side'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'hit': hit,
    'rotation': rotation,
    'zone': zone,
    'direction': direction,
    'side': side,
  };
}