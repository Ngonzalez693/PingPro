// Nombres legibles de los cinco códigos de un golpe (SequenceStep).
//
// Los números son los de pingpro_back/src/utils/enums.ts y están guardados en
// la base: solo se puede añadir al final, nunca reordenar ni reutilizar uno.
//
// Antes cada pantalla tenía su propia copia de estas tablas. Ahora las leen de
// aquí la descripción del detalle, el selector del editor de secuencias y el
// mapper 3D.
//
// Derecha e izquierda son siempre las del jugador, que en la mesa del editor es
// la derecha de la pantalla.
import 'package:pingpro_front/models/sequence_step_model.dart';

/// Códigos de golpe. Espejo de HitCode en pingpro_back/src/utils/enums.ts.
abstract final class HitCode {
  static const int forehand = 1;
  static const int backhand = 2;
  static const int forehandOrBackhand = 3;
  static const int forehandFlick = 4;
  static const int bananaFlick = 5;
  static const int strawberryFlick = 6;
  static const int serve = 7;
  static const int free = 8;
  static const int untilItFalls = 9;
}

/// Las rotaciones que cambian la animación; el resto se anima como topspin.
abstract final class RotationCode {
  static const int backSpin = 1;
  static const int drive = 5;
  static const int liftado = 6;
}

/// Los cinco códigos de SideCode agrupados en las tres zonas en que se
/// grabaron las animaciones. El orden va de derecha a izquierda y el mapper 3D
/// lo usa para saber si un desplazamiento es corto o largo.
enum TableSide { right, center, left }

TableSide tableSideOf(int side) {
  if (side >= 4) return TableSide.left;
  if (side == 3) return TableSide.center;
  return TableSide.right;
}

/// Un forehand desde el lado izquierdo tiene nombre propio en tenis de mesa
/// (pivot) y animaciones propias.
bool isPivot(SequenceStep step) =>
    step.hit == HitCode.forehand && tableSideOf(step.side) == TableSide.left;

const hitLabels = <int, String>{
  1: 'Forehand',
  2: 'Backhand',
  3: 'Forehand/Backhand',
  4: 'Forehand Flick',
  5: 'Banana Flick',
  6: 'Strawberry Flick',
  7: 'Servicio',
  8: 'Libre',
  9: 'Hasta que se caiga',
};

const rotationLabels = <int, String>{
  1: 'Back Spin',
  2: 'Topspin',
  3: 'Side Spin Derecha',
  4: 'Side Spin Izquierda',
  5: 'Drive',
  6: 'Liftado',
  7: 'Libre',
};

/// Profundidad del bote en la mesa del rival.
const zoneLabels = <int, String>{
  1: 'Corto',
  2: 'Intermedio',
  3: 'Largo',
  4: 'Libre',
};

/// Hacia dónde va la pelota, en el lado del rival.
const directionLabels = <int, String>{
  1: 'Lateral Derecho',
  2: 'Esquina Derecha',
  3: 'Medio Derecha',
  4: 'Medio',
  5: 'Medio Izquierdo',
  6: 'Esquina Izquierda',
  7: 'Lateral Izquierda',
  8: 'Libre',
};

/// Desde dónde golpea el jugador, en su lado de la mesa.
const sideLabels = <int, String>{
  1: 'Esquina Derecha',
  2: 'Medio Derecha',
  3: 'Medio',
  4: 'Medio Izquierdo',
  5: 'Esquina Izquierda',
};

/// Nombre de un código, o 'Desconocido' si la base trae uno que la app no
/// conoce todavía (un valor añadido al enum después de publicar esta versión).
String labelOf(Map<int, String> labels, int code) => labels[code] ?? 'Desconocido';

/// Un golpe en una línea: "Forehand Topspin Largo a Esquina Izquierda".
String describeStep(SequenceStep step) {
  final rotation = labelOf(rotationLabels, step.rotation);
  final zone = labelOf(zoneLabels, step.zone);
  final direction = labelOf(directionLabels, step.direction);
  return '${_hitName(step)} $rotation $zone a $direction';
}

String _hitName(SequenceStep step) {
  if (isPivot(step)) return 'Forehand Pivot';
  return labelOf(hitLabels, step.hit);
}
