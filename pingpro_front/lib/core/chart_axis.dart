// Escala del eje Y de las gráficas de estadísticas.
//
// Antes cada gráfica calculaba lo suyo: maxY era exactamente el valor más alto
// de la serie y el intervalo de las líneas de rejilla se sacaba aparte del de
// las etiquetas, así que no coincidían (con maxY 10 la rejilla iba de 2,5 en
// 2,5 y las etiquetas de 1 en 1, y salían decimales).
//
// Aquí se decide una sola vez y las dos gráficas la comparten.

class ChartAxis {
  /// Tope del eje. Siempre deja un intervalo de aire sobre el valor más alto:
  /// si la serie llegara justo al borde, el grosor del trazo se corta por la
  /// mitad al pintarse.
  final double max;

  /// Separación entre líneas de rejilla, que es también la de las etiquetas.
  final double interval;

  const ChartAxis({required this.max, required this.interval});

  /// Escala para una serie de conteos (enteros y nunca negativos).
  ///
  /// Apunta a unas cuatro divisiones: con pocos valores va de uno en uno y a
  /// partir de ahí agranda el paso para no amontonar las etiquetas.
  factory ChartAxis.forValues(List<int> values) {
    final rawMax = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final interval = rawMax <= 4 ? 1 : (rawMax / 4).ceil();
    return ChartAxis(
      max: (interval * ((rawMax ~/ interval) + 1)).toDouble(),
      interval: interval.toDouble(),
    );
  }

  /// Los conteos son enteros: sin esto fl_chart escribe "2.5".
  String label(double value) => value.toInt().toString();
}
