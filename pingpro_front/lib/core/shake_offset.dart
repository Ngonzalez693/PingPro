// Desplazamiento horizontal de la sacudida de error, separado del widget para
// poder testearlo sin animaciones.
import 'dart:math' as math;

const double shakeAmplitude = 8;

// Tres idas y vueltas completas: menos parece un temblor, más un zumbido.
const int _cycles = 3;

/// Desplazamiento en píxeles para el progreso [t] (0 → 1). Una senoidal que
/// se apaga linealmente, así empieza y termina en reposo.
double shakeOffset(double t) =>
    math.sin(t * _cycles * 2 * math.pi) * shakeAmplitude * (1 - t);
