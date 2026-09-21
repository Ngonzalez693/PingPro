// Nombres legibles de los cinco códigos de un golpe (SequenceStep).
//
// Los números son los de pingpro_back/src/utils/enums.ts y están guardados en
// la base: solo se puede añadir al final, nunca reordenar ni reutilizar uno.
//
// Antes cada pantalla tenía su propia copia de estas tablas. Ahora las leen de
// aquí la descripción del detalle y el selector del editor de secuencias; el
// mapper 3D sigue con las suyas porque se reescribe con los nuevos .glb.
//
// Derecha e izquierda son siempre las del jugador, que en la mesa del editor es
// la derecha de la pantalla.
import 'package:pingpro_front/models/sequence_step_model.dart';

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

// Un forehand desde la zona de pivot tiene nombre propio en tenis de mesa: no
// es "Forehand" a secas.
String _hitName(SequenceStep step) {
  final fromPivot = step.side == 4 || step.side == 5;
  if (step.hit == 1 && fromPivot) return 'Forehand Pivot';
  return labelOf(hitLabels, step.hit);
}
