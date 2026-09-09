/**
 * Vocabulario del dominio: codifica un golpe de tenis de mesa como cinco
 * enteros. Es la pieza central de todo el proyecto.
 *
 * Un paso de ejercicio (ISequenceStep) = { hit, rotation, zone, direction, side }.
 * A partir de esos cinco números la app hace dos cosas:
 *   1. Redacta la descripción en texto (pingpro_exercise_detail_screen.dart).
 *   2. Elige qué animación .glb reproducir (core/mappers/exercise_to_glb_steps.dart).
 *
 * IMPORTANTE: los valores numéricos están guardados en Firestore y duplicados a
 * mano en el frontend (Dart no comparte este enum). Cambiar un número aquí
 * rompe los ejercicios ya guardados y desincroniza la app: solo se puede
 * agregar al final, nunca reordenar ni reutilizar un valor.
 */

// Values for hits
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

// Values for rotations
export enum RotationCode {
  BACK_SPIN   = 1,
  TOPSPIN     = 2,
  SIDE_SPIN_R = 3,
  SIDE_SPIN_L = 4,
  DRIVE       = 5,
  LIFTADO     = 6,
  LIBRE       = 7,
}

// Values for table zone
// Profundidad del bote en la mesa contraria.
export enum ZoneCode {
  CORTO      = 1,
  INTERMEDIO = 2,
  LARGO      = 3,
  LIBRE      = 4,
}

// Values for direction
// Hacia dónde va la pelota (lado del rival).
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

// Values for table side
// Desde dónde golpea el jugador. El mapper 3D lo agrupa en DER (1-3),
// PIVOT (4-5) e IZQ (6-7) para escoger la animación de golpe y de desplazamiento.
export enum SideCode {
  ESQUINA_DERECHA   = 1,
  MEDIO_DERECHA     = 2,
  MEDIO             = 3,
  MEDIO_IZQUIERDO   = 4,
  ESQUINA_IZQUIERDA = 5,
}
