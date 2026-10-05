/**
 * Chequeo de arranque: server.ts lo importa ANTES que app.ts.
 *
 * Tiene que ir primero porque el fallo que previene ocurre al cargar
 * firebase-admin (dentro de app.ts): si se comprobara después, el proceso ya
 * habría muerto. Deja la versión en el log para poder confirmarla en el
 * hosting, que solo muestra "22.x".
 */
import { isSupportedNode, MIN_NODE_VERSION } from '../utils/nodeVersion';

console.log(`Node ${process.version}`);

if (!isSupportedNode(process.version)) {
  throw new Error(
    `PingPro necesita Node >= ${MIN_NODE_VERSION} y está corriendo con ${process.version}. ` +
      'Cambia la versión de Node en el panel del hosting.',
  );
}
