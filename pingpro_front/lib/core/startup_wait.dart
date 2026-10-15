// Cuánto dura el splash del arranque con sesión abierta: lo que tarde la carga
// de datos, acotado. El mínimo evita que el splash solo parpadee con buena
// red; el máximo, que una red lenta deje al usuario atrapado en él (la Home ya
// sabe mostrar su propia carga si los datos llegan después).
import 'dart:async';

const startupMinimum = Duration(milliseconds: 1500);
const startupMaximum = Duration(seconds: 6);

/// Termina cuando termina `work`, pero nunca antes de `min` ni después de `max`.
Future<void> waitForStartup(
  Future<void> work, {
  Duration min = startupMinimum,
  Duration max = startupMaximum,
}) async {
  // `work` puede ser en realidad un Future<List<void>> (Future.wait) y timeout
  // comprueba onTimeout contra ese tipo real: con then<void> se espera siempre
  // a un Future<void> de verdad.
  await Future.wait([
    Future<void>.delayed(min),
    work.then<void>((_) {}).timeout(max, onTimeout: () {}),
  ]);
}
