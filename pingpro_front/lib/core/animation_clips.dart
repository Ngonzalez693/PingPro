// Nombres de los clips de PingProAnimations.glb, el único archivo 3D de la app
// (fila 'PingPro Animations' de models_3d).
//
// Cada clip se llama como el .glb del que salió al unir las animaciones en
// Blender. Este archivo es el único sitio donde se escriben: si uno no existe
// en el .glb, el visor lo avisa en consola y se salta ese paso.
//
// El archivo trae además Hook, Globo, Smash, CorteAtras y DesIzqDer, que
// ninguna regla usa todavía.
abstract final class AnimationClip {
  static const posInicial = 'PosInicial';

  static const saquePendulo = 'SaquePendulo';
  static const saqueInv = 'SaqueInv';
  static const saqueReves = 'SaqueReves';

  static const topspinForehand = 'TopspinForehand';
  static const topspinPivot = 'TopspinPivot';
  static const loopDerecha = 'LoopDerecha';
  static const loopPivot = 'LoopPivot';
  static const corteDer = 'CorteDer';

  static const topspinBackhand = 'Topspin_Backhand_000';
  static const inicioReves = 'InicioReves';
  static const corteReves = 'CorteReves';
  static const reves = 'Reves';

  static const flip = 'Flip';
  static const ning = 'Ning';
  static const ningDer = 'NingDer';
  static const boomerang = 'Boomerang';

  static const movCortoDerIzq = 'MovCortoDerIzq';
  static const movCortoIzqDer = 'MovCortoIzqDer';
  static const movLargoDerIzq = 'MovLargoDerIzq';
  static const movLargoIzqDer = 'MovLargoIzqDer';
  static const movCortoApivot = 'MovCortoApivot';
  static const movLargoPivotDer = 'MovLargoPivotDer';
  static const movLargoCruce = 'MovLargoCruce';
}
