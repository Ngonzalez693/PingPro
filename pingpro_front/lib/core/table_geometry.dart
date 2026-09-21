// Geometría de la mesa del editor de secuencias: dónde están los puntos de
// golpeo y de destino, y qué códigos de golpe da cada uno.
//
// Todo se mide en "coordenadas de mesa", de 0 a 1 en cada eje:
//   x: 0 = banda izquierda, 1 = banda derecha (derecha del jugador = derecha
//      de la pantalla)
//   y: 0 = fondo del rival (arriba), 1 = fondo del jugador (abajo); la red
//      está en 0.5
// Así nada depende de píxeles y la misma regla vale en cualquier pantalla.
// Pasar a y desde píxeles es cosa de toTable() y toCanvas().
//
// Los números de los códigos son los de core/stroke_codes.dart.
import 'dart:math' as math;
import 'dart:ui';

/// Ancho entre largo de una mesa reglamentaria (1,525 m × 2,74 m).
const tableAspectRatio = 1.525 / 2.74;

/// Posición de la red en y.
const netY = 0.5;

/// Hueco a cada lado de la mesa, como fracción del lienzo: los puntos de las
/// bandas quedan medio fuera de la mesa y necesitan sitio.
const _lateralMargin = 0.18;

/// Punto desde el que golpea el jugador.
typedef StrokeOrigin = ({Offset position, int side});

/// Punto donde bota la pelota en el campo del rival.
typedef StrokeTarget = ({Offset position, int direction, int zone});

// Filas de puntos, medidas desde la red hacia cada fondo. Los dos campos son
// simétricos: la fila corta de un lado es el reflejo de la del otro.
const _shortDepth = 0.08; // junto a la red
const _middleDepth = 0.25;
const _longDepth = 0.43; // junto al fondo
const _lateralDepth = (_shortDepth + _longDepth) / 2;

// Cinco columnas iguales. Columna 0 = izquierda de la pantalla.
double _columnX(int column) => (column + 0.5) / 5;

/// Puntos de golpeo del jugador, en este orden:
///   0–4   fila larga, de izquierda a derecha
///   5–9   fila corta, de izquierda a derecha
///   10    banda izquierda
///   11    banda derecha
///
/// El backend solo guarda el lado de izquierda a derecha (SideCode 1–5), no la
/// profundidad: la fila corta guarda el mismo lado que la larga de su columna,
/// y las bandas el de su esquina. Se dibujan igual para que el ejercicio se
/// entienda, pero al guardarse esa diferencia se pierde.
final List<StrokeOrigin> strokeOrigins = [
  for (final depth in [_longDepth, _shortDepth])
    for (var column = 0; column < 5; column++)
      (position: Offset(_columnX(column), netY + depth), side: _sideForColumn(column)),
  (position: const Offset(0, netY + _lateralDepth), side: 5), // esquina izquierda
  (position: const Offset(1, netY + _lateralDepth), side: 1), // esquina derecha
];

/// Puntos de destino en el campo del rival: filas larga, media y corta, y las
/// dos bandas. Son el reflejo de los de golpeo más una fila media, para que
/// "intermedio" exista en todas las columnas y no solo en las bandas.
final List<StrokeTarget> strokeTargets = [
  for (final (depth, zone) in [(_longDepth, 3), (_middleDepth, 2), (_shortDepth, 1)])
    for (var column = 0; column < 5; column++)
      (position: Offset(_columnX(column), netY - depth), direction: _directionForColumn(column), zone: zone),
  (position: const Offset(0, netY - _lateralDepth), direction: 7, zone: 2), // lateral izquierdo
  (position: const Offset(1, netY - _lateralDepth), direction: 1, zone: 2), // lateral derecho
];

// La derecha es la del jugador: columna 4 (derecha) = esquina derecha (1),
// columna 0 (izquierda) = esquina izquierda (5).
int _sideForColumn(int column) => 5 - column;

// Columna 0 = esquina izquierda (6) … columna 4 = esquina derecha (2).
int _directionForColumn(int column) => 6 - column;

/// El punto de destino al que se engancha una flecha soltada en `point`, o
/// null si está en tu propio campo (ahí soltarla no es un golpe).
///
/// Se engancha al más cercano, esté donde esté en el campo del rival: así no
/// hace falta acertar el punto exacto, y la flecha muestra a cuál irá antes de
/// soltarla.
StrokeTarget? snapTarget(Offset point) {
  if (point.dy >= netY) return null;
  return strokeTargets.reduce(
    (best, t) => _distance(t.position, point) < _distance(best.position, point) ? t : best,
  );
}

// Distancia en "altos de mesa": x va en anchos, así que se escala por la
// proporción para que un paso en horizontal valga lo mismo que en vertical.
double _distance(Offset a, Offset b) {
  final dx = (a.dx - b.dx) * tableAspectRatio;
  final dy = a.dy - b.dy;
  return math.sqrt(dx * dx + dy * dy);
}

/// Rectángulo de la mesa dentro de un lienzo de tamaño `canvas`: centrado, con
/// las proporciones reales y dejando hueco a los lados para las bandas.
Rect tableRectFor(Size canvas) {
  var width = canvas.width * (1 - 2 * _lateralMargin);
  var height = width / tableAspectRatio;
  if (height > canvas.height) {
    height = canvas.height;
    width = height * tableAspectRatio;
  }
  final left = (canvas.width - width) / 2;
  final top = (canvas.height - height) / 2;
  return Rect.fromLTWH(left, top, width, height);
}

/// Punto del lienzo (píxeles) → coordenadas de mesa. Puede salir de 0..1.
Offset toTable(Offset canvasPoint, Rect table) => Offset(
      (canvasPoint.dx - table.left) / table.width,
      (canvasPoint.dy - table.top) / table.height,
    );

/// Coordenadas de mesa → punto del lienzo (píxeles).
Offset toCanvas(Offset tablePoint, Rect table) => Offset(
      table.left + tablePoint.dx * table.width,
      table.top + tablePoint.dy * table.height,
    );

/// Índice del punto de golpeo bajo `canvasPoint`, a menos de `radius`
/// píxeles, o null si el dedo no empezó sobre ninguno.
int? originAt(Offset canvasPoint, Rect table, double radius) {
  int? nearest;
  var nearestDistance = radius;
  for (var i = 0; i < strokeOrigins.length; i++) {
    final distance = (toCanvas(strokeOrigins[i].position, table) - canvasPoint).distance;
    if (distance <= nearestDistance) {
      nearest = i;
      nearestDistance = distance;
    }
  }
  return nearest;
}
