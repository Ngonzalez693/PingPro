// Enlace mailto de "Reportar un problema".
//
// La query se arma a mano con encodeComponent: Uri(queryParameters:) codifica
// los espacios como "+", y la mayoría de los clientes de correo los muestran
// literalmente en el asunto.

/// null si no hay correo de soporte configurado (la opción no se muestra).
Uri? supportMailUri({required String? email, required String version}) {
  final to = email?.trim() ?? '';
  if (to.isEmpty) return null;
  final params = {
    'subject': 'PingPro: reporte de problema',
    'body': 'Versión de la app: $version\n\nCuéntanos qué pasó:\n',
  };
  final query = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return Uri(scheme: 'mailto', path: to, query: query);
}
