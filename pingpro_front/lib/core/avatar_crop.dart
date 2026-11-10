// Cuentas del recorte de la foto de perfil.
import 'dart:math' as math;
import 'dart:ui';

/// Lado en píxeles de la foto que se sube: suficiente para el avatar y ligera.
const int avatarPixels = 512;

/// Escala mínima a la que la foto cubre un cuadrado de [circleDiameter]: por
/// debajo quedarían esquinas vacías dentro del círculo.
double coverScale(Size image, double circleDiameter) =>
    math.max(circleDiameter / image.width, circleDiameter / image.height);
