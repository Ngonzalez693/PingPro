// Cliente HTTP de todas las llamadas al backend, con un límite de tiempo por
// petición.
//
// Sin límite, una petición que se queda colgada (red móvil que se corta a
// medias) no termina nunca: la pantalla se queda en skeletons y, como los
// stores ignoran una recarga mientras otra sigue en curso, ni "Reintentar" ni
// tirar para recargar la desatascan. Con él falla con TimeoutException, que
// core/load_errors.dart ya trata como "sin conexión".
import 'package:http/http.dart' as http;

const requestTimeout = Duration(seconds: 15);

/// El mismo límite para lo que va antes de la petición, como pedir el ID token
/// de Firebase: sin red se queda colgado igual que la petición, y ahí no llega
/// el límite del cliente.
Future<T> withRequestTimeout<T>(Future<T> work) => work.timeout(requestTimeout);

class TimeoutClient extends http.BaseClient {
  final http.Client _inner;

  TimeoutClient(this._inner);

  // El límite cubre hasta que llegan las cabeceras de la respuesta; el cuerpo
  // de estas respuestas es pequeño.
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      withRequestTimeout(_inner.send(request));

  @override
  void close() => _inner.close();
}

/// El que usan los servicios en vez de las funciones sueltas de `http`.
final apiClient = TimeoutClient(http.Client());
