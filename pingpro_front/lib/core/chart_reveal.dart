// Cálculos del trazo animado de StatisticsChart, separados del widget para
// testearlos sin pintar nada.
//
// La línea se revela con un gradiente horizontal opaco hasta [progress] y
// transparente después. fl_chart extiende ese gradiente del primer al último
// punto, así que `progress` equivale a la fracción de x recorrida.

/// Stops del gradiente: color hasta [progress], transparente desde ahí.
/// Se usan con 4 colores: [opaco, opaco, transparente, transparente].
List<double> revealStops(double progress) {
  final t = progress.clamp(0.0, 1.0);
  return [0, t, t, 1];
}

/// Si la línea ya llegó al punto de coordenada [x].
bool isRevealed({
  required double x,
  required double maxX,
  required double progress,
}) =>
    x <= progress * maxX;
