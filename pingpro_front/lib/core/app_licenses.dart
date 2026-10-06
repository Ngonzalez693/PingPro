// Licencias que Flutter no registra solo en la pantalla de licencias.
//
// Las de los paquetes de pub entran automáticamente; las de las fuentes
// empaquetadas no, y la OFL de Anta exige incluir su aviso.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerAppLicenses() {
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Anta'], ofl);
  });
}
