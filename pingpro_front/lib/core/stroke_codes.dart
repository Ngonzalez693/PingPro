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
  static const int hook = 10;
  static const int globo = 11;
  static const int smash = 12;
}

/// Códigos de rotación con nombre en el código: los que tienen reglas propias
/// o cambian la animación. Espejo de RotationCode en enums.ts.
abstract final class RotationCode {
  static const int backSpin = 1;
  static const int topspin = 2;
  static const int sideSpinRight = 3;
  static const int sideSpinLeft = 4;
  static const int drive = 5;
  static const int liftado = 6;
}

/// Profundidad: la del bote en la mesa del rival (zone) o la del jugador en
/// su propio campo (ownZone). Espejo de ZoneCode en enums.ts.
abstract final class ZoneCode {
  static const int short = 1;
  static const int middle = 2;
  static const int long = 3;
  static const int free = 4;
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
  10: 'Hook',
  11: 'Globo',
  12: 'Smash',
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

/// Profundidad, en la mesa del rival (zone) o en la propia (ownZone).
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

// Golpes que solo admiten algunas rotaciones; los demás admiten todas.
// Espejo de ALLOWED_ROTATIONS en pingpro_back/src/utils/exercise.validator.ts.
const _restrictedRotations = <int, List<int>>{
  HitCode.hook: [RotationCode.backSpin],
  HitCode.globo: [
    RotationCode.topspin,
    RotationCode.sideSpinRight,
    RotationCode.sideSpinLeft,
    RotationCode.drive,
  ],
  HitCode.smash: [RotationCode.topspin, RotationCode.drive],
};

// Golpes que solo se juegan desde el fondo del propio campo.
// Espejo de LONG_ONLY_HITS en pingpro_back/src/utils/exercise.validator.ts.
const _longOnlyHits = {HitCode.globo, HitCode.smash};

/// Rotaciones que admite un golpe, en el orden de rotationLabels.
List<int> allowedRotations(int hit) =>
    _restrictedRotations[hit] ?? rotationLabels.keys.toList();

/// Golpes que se pueden elegir golpeando desde la profundidad [ownZone].
List<int> hitsAvailableFrom(int ownZone) => [
      for (final hit in hitLabels.keys)
        if (ownZone == ZoneCode.long || !_longOnlyHits.contains(hit)) hit,
    ];

/// Un golpe en una línea: "Forehand Topspin desde Largo, Largo a Esquina
/// Izquierda". Sin profundidad propia (Libre) se omite el "desde …", como en
/// los pasos guardados antes de que existiera.
String describeStep(SequenceStep step) {
  final rotation = labelOf(rotationLabels, step.rotation);
  final zone = labelOf(zoneLabels, step.zone);
  final direction = labelOf(directionLabels, step.direction);
  final from = step.ownZone == ZoneCode.free ? '' : ' desde ${labelOf(zoneLabels, step.ownZone)},';
  return '${_hitName(step)} $rotation$from $zone a $direction';
}

String _hitName(SequenceStep step) {
  if (isPivot(step)) return 'Forehand Pivot';
  return labelOf(hitLabels, step.hit);
}
