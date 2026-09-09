/**
 * Contrato de un modelo 3D (documento de la colección 'model3d').
 *
 * `name` no es decorativo: es la llave con la que el mapper del frontend busca
 * la animación (p. ej. 'Forehand Topspin', 'MovLargoDerIzq'). Debe coincidir
 * exactamente con los nombres de exercise_to_glb_steps.dart.
 * `url` apunta al archivo .glb alojado fuera de Firestore.
 */
export interface IModel3D {
  id?: string;
  name: string;
  url: string;
  createdAt: Date;
  updatedAt: Date;
}
