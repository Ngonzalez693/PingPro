// Licencias que Flutter no registra solo en la pantalla de licencias.
//
// Las de los paquetes de pub entran automáticamente; las de lo que se empaqueta
// a mano no: la OFL de la fuente Anta y la MIT de three.js (el visor 3D) exigen
// incluir su aviso.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerAppLicenses() {
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Anta'], ofl);
    final three = await rootBundle.loadString('assets/viewer/LICENSE-three.txt');
    yield LicenseEntryWithLineBreaks(['three.js'], three);
  });
}
