// Mensaje de error de una respuesta del backend, para enseñarlo al usuario.
//
// Según quién responda viene en un campo distinto: `message` desde los
// controladores (utils/apiResponse) y `error` desde la validación Joi y el
// authMiddleware. Si no hay ninguno, o el cuerpo no es JSON, se usa `fallback`.
import 'dart:convert';

String backendErrorMessage(String body, String fallback) {
  try {
    final data = jsonDecode(body);
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
  } on FormatException {
    return fallback;
  }
}
