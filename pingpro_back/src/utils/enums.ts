// Valores para golpes
export enum HitCode {
  FOREHAND           = 1,
  BACKHAND           = 2,
  FOREHAND_BACKHAND  = 3,
  FOREHAND_FLICK     = 4,
  BANANA_FLICK       = 5,
  STRAWBERRY_FLICK   = 6,
  SERVICIO           = 7,
  LIBRE              = 8,
  HASTA_QUE_SE_CAIGA = 9,
}

// Valores para rotaciones
export enum RotationCode {
  BACK_SPIN   = 1,
  TOPSPIN     = 2,
  SIDE_SPIN_R = 3,
  SIDE_SPIN_L = 4,
  DRIVE       = 5,
  LIFTADO     = 6,
  LIBRE       = 7,
}

// Valores para zona de la mesa
export enum ZoneCode {
  CORTO      = 1,
  INTERMEDIO = 2,
  LARGO      = 3,
  LIBRE      = 4,
}

// Valores para dirección
export enum DirectionCode {
  LATERAL_DERECHO   = 1,
  ESQUINA_DERECHA   = 2,
  MEDIO_DERECHA     = 3,
  MEDIO             = 4,
  MEDIO_IZQUIERDO   = 5,
  ESQUINA_IZQUIERDA = 6,
  LATERAL_IZQUIERDO = 7,
  LIBRE             = 8,
}

export enum SideCode {
  ESQUINA_DERECHA   = 1,
  MEDIO_DERECHA     = 2,
  MEDIO             = 3,
  MEDIO_IZQUIERDO   = 4,
  ESQUINA_IZQUIERDA = 5,
}
