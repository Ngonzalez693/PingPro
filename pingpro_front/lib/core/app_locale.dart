// Idioma de la app para los textos que pone Flutter y no nosotros, como el menú
// de cortar, copiar y pegar de un campo de texto. La app solo está en español,
// así que se usa este idioma aunque el teléfono esté en otro.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const appLocalizationsDelegates = GlobalMaterialLocalizations.delegates;
const appSupportedLocales = [Locale('es')];
