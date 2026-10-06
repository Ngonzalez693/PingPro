import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(LicenseRegistry.reset);

  test('registra la licencia OFL de la fuente Anta', () async {
    registerAppLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final anta = entries.where((e) => e.packages.contains('Anta'));

    expect(anta, hasLength(1));
    final text = anta.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('SIL Open Font License'));
  });
}
