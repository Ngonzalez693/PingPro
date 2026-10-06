import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/support_mail.dart';

void main() {
  group('supportMailUri', () {
    test('sin correo configurado no hay enlace', () {
      expect(supportMailUri(email: null, version: '0.1.0 (1)'), isNull);
      expect(supportMailUri(email: '', version: '0.1.0 (1)'), isNull);
      expect(supportMailUri(email: '   ', version: '0.1.0 (1)'), isNull);
    });

    test('va dirigido al correo de soporte', () {
      final uri = supportMailUri(email: 'pingproteam@gmail.com', version: '0.1.0 (1)')!;

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'pingproteam@gmail.com');
    });

    test('lleva asunto y versión, con espacios como %20 y no como +', () {
      final uri = supportMailUri(email: 'pingproteam@gmail.com', version: '0.1.0 (1)')!;

      expect(uri.query, contains('subject=PingPro%3A%20reporte%20de%20problema'));
      expect(uri.query, isNot(contains('+')));
      expect(Uri.decodeComponent(uri.query), contains('0.1.0 (1)'));
    });
  });
}
